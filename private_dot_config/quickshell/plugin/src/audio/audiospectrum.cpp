#include "audiospectrum.hpp"

#include <QDebug>

#include <algorithm>
#include <cmath>
#include <memory>
#include <mutex>
#include <numbers>

#include <fftw3.h>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>

struct PwMainLoopDeleter {
    void operator()(pw_main_loop* p) const noexcept { pw_main_loop_destroy(p); }
};
struct PwContextDeleter {
    void operator()(pw_context* p) const noexcept { pw_context_destroy(p); }
};
struct PwCoreDeleter {
    void operator()(pw_core* p) const noexcept { pw_core_disconnect(p); }
};
struct PwStreamDeleter {
    void operator()(pw_stream* p) const noexcept { pw_stream_destroy(p); }
};

using UniquePwMainLoop = std::unique_ptr<pw_main_loop, PwMainLoopDeleter>;
using UniquePwContext = std::unique_ptr<pw_context, PwContextDeleter>;
using UniquePwCore = std::unique_ptr<pw_core, PwCoreDeleter>;
using UniquePwStream = std::unique_ptr<pw_stream, PwStreamDeleter>;

static std::once_flag s_pwInitFlag;

static void ensurePipewireInit() {
    std::call_once(s_pwInitFlag, [] { pw_init(nullptr, nullptr); });
}

void pwOnStreamProcess(void* userdata) {
    auto* self = static_cast<AudioSpectrum*>(userdata);

    pw_buffer* pwBuf = pw_stream_dequeue_buffer(self->m_stream);
    if (!pwBuf) return;

    spa_buffer* spaBuf = pwBuf->buffer;
    auto* samples = static_cast<float*>(spaBuf->datas[0].data);

    if (!samples) {
        pw_stream_queue_buffer(self->m_stream, pwBuf);
        return;
    }

    const uint32_t nSamples = spaBuf->datas[0].chunk->size / sizeof(float);

    int writePos = self->m_writePos.load(std::memory_order_relaxed);
    for (uint32_t i = 0; i < nSamples; ++i) {
        self->m_ringBuffer[static_cast<size_t>(writePos)] = samples[i];
        writePos = (writePos + 1) % AudioSpectrum::BUFFER_SIZE;
    }
    self->m_writePos.store(writePos, std::memory_order_release);

    pw_stream_queue_buffer(self->m_stream, pwBuf);
}

static void pwOnStreamStateChanged(void* /*userdata*/, enum pw_stream_state /*old*/,
                                   enum pw_stream_state state, const char* error) {
    switch (state) {
    case PW_STREAM_STATE_ERROR:
        qWarning() << "[AudioSpectrum] Stream error:" << (error ? error : "unknown");
        break;
    case PW_STREAM_STATE_STREAMING:
        qDebug() << "[AudioSpectrum] Streaming started";
        break;
    case PW_STREAM_STATE_PAUSED:
        qDebug() << "[AudioSpectrum] Stream paused";
        break;
    default:
        break;
    }
}

static constexpr pw_stream_events kStreamEvents = [] {
    pw_stream_events e{};
    e.version = PW_VERSION_STREAM_EVENTS;
    e.state_changed = pwOnStreamStateChanged;
    e.process = pwOnStreamProcess;
    return e;
}();

AudioSpectrum::AudioSpectrum(QObject* parent)
    : QObject(parent),
      m_ringBuffer(BUFFER_SIZE, 0.0f),
      m_magnitudes(SPECTRUM_SIZE, 0.0),
      m_smoothedBars(m_barCount, 0.0) {

    ensurePipewireInit();

    m_fftIn = fftw_alloc_real(FFT_SIZE);
    auto* complexBuf = fftw_alloc_complex(FFT_SIZE / 2 + 1);
    m_fftOut = reinterpret_cast<double*>(complexBuf);
    m_fftPlan = fftw_plan_dft_r2c_1d(FFT_SIZE, m_fftIn, complexBuf, FFTW_MEASURE);

    precomputeWindow();
    precomputeBandBins();
    initBars();

    m_processTimer.setTimerType(Qt::PreciseTimer);
    connect(&m_processTimer, &QTimer::timeout, this, &AudioSpectrum::processFFT);
}

AudioSpectrum::~AudioSpectrum() {
    stopCapture();

    if (m_fftPlan) fftw_destroy_plan(m_fftPlan);
    if (m_fftIn) fftw_free(m_fftIn);
    if (m_fftOut) fftw_free(m_fftOut);
}

QVariantList AudioSpectrum::bars() const { return m_bars; }
int AudioSpectrum::barCount() const { return m_barCount; }
int AudioSpectrum::fps() const { return m_fps; }
bool AudioSpectrum::active() const { return m_active; }
qreal AudioSpectrum::smoothing() const { return m_smoothing; }
qreal AudioSpectrum::sensitivity() const { return m_sensitivity; }
qreal AudioSpectrum::peak() const { return m_peak; }

void AudioSpectrum::setBarCount(int count) {
    count = std::clamp(count, 2, 128);
    if (m_barCount == count) return;

    m_barCount = count;
    m_smoothedBars.assign(static_cast<size_t>(count), 0.0);
    m_newBars.resize(static_cast<size_t>(count));
    precomputeBandBins();
    initBars();
    emit barCountChanged();
}

void AudioSpectrum::setFps(int fps) {
    fps = std::clamp(fps, 5, 120);
    if (m_fps == fps) return;

    m_fps = fps;
    if (m_processTimer.isActive()) {
        m_processTimer.setInterval(1000 / m_fps);
    }
    emit fpsChanged();
}

void AudioSpectrum::setActive(bool active) {
    if (m_active == active) return;

    m_active = active;
    if (active) startCapture();
    else        stopCapture();
    emit activeChanged();
}

void AudioSpectrum::setSmoothing(qreal smoothing) {
    smoothing = std::clamp(smoothing, 0.0, 0.99);
    if (qFuzzyCompare(m_smoothing, smoothing)) return;

    m_smoothing = smoothing;
    emit smoothingChanged();
}

void AudioSpectrum::setSensitivity(qreal sensitivity) {
    sensitivity = std::clamp(sensitivity, 0.1, 10.0);
    if (qFuzzyCompare(m_sensitivity, sensitivity)) return;

    m_sensitivity = sensitivity;
    emit sensitivityChanged();
}

void AudioSpectrum::precomputeWindow() {
    m_window.resize(FFT_SIZE);
    constexpr double twoPi = 2.0 * std::numbers::pi;
    const double denom = static_cast<double>(FFT_SIZE - 1);

    for (int i = 0; i < FFT_SIZE; ++i) {
        m_window[static_cast<size_t>(i)] =
            0.5 * (1.0 - std::cos(twoPi * static_cast<double>(i) / denom));
    }
}

void AudioSpectrum::precomputeBandBins() {
    const auto barCount = static_cast<size_t>(m_barCount);
    m_bandBins.resize(barCount);
    m_newBars.resize(barCount);

    const double logMin = std::log10(kMinFreq);
    const double logMax = std::log10(kMaxFreq);
    const double logRange = logMax - logMin;

    for (int band = 0; band < m_barCount; ++band) {
        const double freqLow = std::pow(10.0, logMin + logRange * band / m_barCount);
        const double freqHigh = std::pow(10.0, logMin + logRange * (band + 1) / m_barCount);

        int binLow = static_cast<int>(std::floor(freqLow * FFT_SIZE / kSampleRate));
        int binHigh = static_cast<int>(std::ceil(freqHigh * FFT_SIZE / kSampleRate));

        binLow = std::clamp(binLow, 1, SPECTRUM_SIZE - 1);
        binHigh = std::clamp(binHigh, binLow + 1, SPECTRUM_SIZE);

        m_bandBins[static_cast<size_t>(band)] = {binLow, binHigh};
    }
}

void AudioSpectrum::initBars() {
    m_bars.clear();
    m_bars.reserve(m_barCount);
    for (int i = 0; i < m_barCount; ++i) {
        m_bars.append(0.0);
    }
}

void AudioSpectrum::pipewireThreadFunc() {
    UniquePwMainLoop loop(pw_main_loop_new(nullptr));
    if (!loop) {
        qWarning() << "[AudioSpectrum] Failed to create PW main loop";
        return;
    }

    UniquePwContext context(pw_context_new(pw_main_loop_get_loop(loop.get()), nullptr, 0));
    if (!context) {
        qWarning() << "[AudioSpectrum] Failed to create PW context";
        return;
    }

    UniquePwCore core(pw_context_connect(context.get(), nullptr, 0));
    if (!core) {
        qWarning() << "[AudioSpectrum] Failed to connect PW context";
        return;
    }

    pw_properties* props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio",
        PW_KEY_MEDIA_CATEGORY, "Capture",
        PW_KEY_MEDIA_ROLE, "DSP",
        PW_KEY_STREAM_CAPTURE_SINK, "true",
        PW_KEY_NODE_NAME, "quickshell-spectrum",
        PW_KEY_APP_NAME, "QuickShell Spectrum",
        nullptr);

    UniquePwStream stream(pw_stream_new(core.get(), "audio-spectrum", props));
    if (!stream) {
        qWarning() << "[AudioSpectrum] Failed to create PW stream";
        return;
    }

    m_loop = loop.get();
    m_stream = stream.get();

    struct spa_hook streamListener{};
    pw_stream_add_listener(stream.get(), &streamListener, &kStreamEvents, this);

    uint8_t paramBuffer[1024];
    struct spa_pod_builder builder{};
    builder.data = paramBuffer;
    builder.size = sizeof(paramBuffer);

    struct spa_audio_info_raw audioInfo{};
    audioInfo.format = SPA_AUDIO_FORMAT_F32;
    audioInfo.rate = 44100;
    audioInfo.channels = 1;

    const spa_pod* params[] = {
        spa_format_audio_raw_build(&builder, SPA_PARAM_EnumFormat, &audioInfo),
    };

    pw_stream_connect(stream.get(), PW_DIRECTION_INPUT, PW_ID_ANY,
                      static_cast<pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT |
                                                    PW_STREAM_FLAG_MAP_BUFFERS |
                                                    PW_STREAM_FLAG_RT_PROCESS),
                      params, 1);

    pw_main_loop_run(loop.get());

    m_stream = nullptr;
    m_loop = nullptr;
}

void AudioSpectrum::startCapture() {
    m_writePos.store(0, std::memory_order_relaxed);
    std::fill(m_ringBuffer.begin(), m_ringBuffer.end(), 0.0f);
    m_smoothedBars.assign(static_cast<size_t>(m_barCount), 0.0);

    m_pwThread = QThread::create([this]() { pipewireThreadFunc(); });
    m_pwThread->setObjectName(QStringLiteral("AudioSpectrum-PW"));
    m_pwThread->start();

    m_processTimer.setInterval(1000 / m_fps);
    m_processTimer.start();

    qDebug() << "[AudioSpectrum] Capture started, barCount=" << m_barCount
             << "fps=" << m_fps;
}

void AudioSpectrum::stopCapture() {
    m_processTimer.stop();

    if (m_loop) {
        pw_main_loop_quit(m_loop);
    }

    if (m_pwThread && m_pwThread->isRunning()) {
        m_pwThread->quit();
        m_pwThread->wait(2000);
        if (m_pwThread->isRunning()) {
            m_pwThread->terminate();
            m_pwThread->wait(500);
        }
        m_pwThread->deleteLater();
        m_pwThread = nullptr;
    }

    m_smoothedBars.assign(static_cast<size_t>(m_barCount), 0.0);
    initBars();
    emit barsChanged();

    qDebug() << "[AudioSpectrum] Capture stopped";
}

void AudioSpectrum::processFFT() {
    const int writePos = m_writePos.load(std::memory_order_acquire);

    for (int i = 0; i < FFT_SIZE; ++i) {
        const int idx = (writePos - FFT_SIZE + i + BUFFER_SIZE) % BUFFER_SIZE;
        m_fftIn[i] = static_cast<double>(m_ringBuffer[static_cast<size_t>(idx)])
                     * m_window[static_cast<size_t>(i)];
    }

    fftw_execute(m_fftPlan);

    auto* complexOut = reinterpret_cast<fftw_complex*>(m_fftOut);
    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        const double re = complexOut[i][0];
        const double im = complexOut[i][1];
        m_magnitudes[static_cast<size_t>(i)] = std::sqrt(re * re + im * im) / FFT_SIZE;
    }

    double peakVal = 0.0;
    for (int band = 0; band < m_barCount; ++band) {
        const auto [binLow, binHigh] = m_bandBins[static_cast<size_t>(band)];

        double sum = 0.0;
        for (int bin = binLow; bin < binHigh; ++bin) {
            sum += m_magnitudes[static_cast<size_t>(bin)];
        }

        const double avg = sum / static_cast<double>(binHigh - binLow);
        double val = avg * m_sensitivity * kSensitivityScale;

        val = (val > kMinMagnitude) ? (std::log10(val * kLogBase + 1.0) / kLogDivisor) : 0.0;
        val = std::clamp(val, 0.0, 1.0);

        m_newBars[static_cast<size_t>(band)] = val;
        peakVal = std::max(peakVal, val);
    }

    bool changed = false;
    for (int i = 0; i < m_barCount; ++i) {
        const auto idx = static_cast<size_t>(i);
        const double target = m_newBars[idx];
        const double current = m_smoothedBars[idx];

        const double alpha = (target > current)
                                 ? (1.0 - m_smoothing * 0.5)
                                 : (1.0 - m_smoothing);

        double smoothed = current + alpha * (target - current);

        if (smoothed < kMinBarThreshold) smoothed = 0.0;

        if (std::abs(m_smoothedBars[idx] - smoothed) > kChangeEpsilon) {
            m_smoothedBars[idx] = smoothed;
            changed = true;
        }
    }

    if (changed) {
        for (int i = 0; i < m_barCount; ++i) {
            m_bars[i] = m_smoothedBars[static_cast<size_t>(i)];
        }
        emit barsChanged();
    }

    if (!qFuzzyCompare(m_peak, peakVal)) {
        m_peak = peakVal;
        emit peakChanged();
    }
}
