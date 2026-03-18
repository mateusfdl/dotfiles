#pragma once

#include <QObject>
#include <QThread>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

#include <atomic>
#include <utility>
#include <vector>

struct pw_main_loop;
struct pw_stream;
struct fftw_plan_s;

class AudioSpectrum : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList bars READ bars NOTIFY barsChanged)
    Q_PROPERTY(int barCount READ barCount WRITE setBarCount NOTIFY barCountChanged)
    Q_PROPERTY(int fps READ fps WRITE setFps NOTIFY fpsChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(qreal smoothing READ smoothing WRITE setSmoothing NOTIFY smoothingChanged)
    Q_PROPERTY(qreal sensitivity READ sensitivity WRITE setSensitivity NOTIFY sensitivityChanged)
    Q_PROPERTY(qreal peak READ peak NOTIFY peakChanged)

public:
    explicit AudioSpectrum(QObject* parent = nullptr);
    ~AudioSpectrum() override;

    AudioSpectrum(const AudioSpectrum&) = delete;
    AudioSpectrum& operator=(const AudioSpectrum&) = delete;

    [[nodiscard]] QVariantList bars() const;
    [[nodiscard]] int barCount() const;
    [[nodiscard]] int fps() const;
    [[nodiscard]] bool active() const;
    [[nodiscard]] qreal smoothing() const;
    [[nodiscard]] qreal sensitivity() const;
    [[nodiscard]] qreal peak() const;

    void setBarCount(int count);
    void setFps(int fps);
    void setActive(bool active);
    void setSmoothing(qreal smoothing);
    void setSensitivity(qreal sensitivity);

signals:
    void barsChanged();
    void barCountChanged();
    void fpsChanged();
    void activeChanged();
    void smoothingChanged();
    void sensitivityChanged();
    void peakChanged();

private slots:
    void processFFT();

private:
    void startCapture();
    void stopCapture();
    void pipewireThreadFunc();
    void precomputeWindow();
    void precomputeBandBins();
    void initBars();

    friend void pwOnStreamProcess(void* userdata);

    static constexpr int BUFFER_SIZE = 8192;
    static constexpr int FFT_SIZE = 2048;
    static constexpr int SPECTRUM_SIZE = FFT_SIZE / 2 + 1;

    static constexpr double kSampleRate = 44100.0;
    static constexpr double kMinFreq = 60.0;
    static constexpr double kMaxFreq = 16000.0;
    static constexpr double kSensitivityScale = 100.0;
    static constexpr double kLogBase = 1000.0;
    static constexpr double kLogDivisor = 3.0;
    static constexpr double kMinMagnitude = 0.0001;
    static constexpr double kMinBarThreshold = 0.01;
    static constexpr double kChangeEpsilon = 0.001;

    QThread* m_pwThread = nullptr;
    pw_main_loop* m_loop = nullptr;
    pw_stream* m_stream = nullptr;

    std::vector<float> m_ringBuffer;
    std::atomic<int> m_writePos{0};

    double* m_fftIn = nullptr;
    double* m_fftOut = nullptr;
    fftw_plan_s* m_fftPlan = nullptr;

    int m_barCount = 32;
    int m_fps = 30;
    bool m_active = false;
    qreal m_smoothing = 0.65;
    qreal m_sensitivity = 1.5;

    std::vector<double> m_window;
    std::vector<double> m_magnitudes;
    std::vector<double> m_newBars;
    std::vector<std::pair<int, int>> m_bandBins;

    QVariantList m_bars;
    std::vector<double> m_smoothedBars;
    qreal m_peak = 0.0;

    QTimer m_processTimer;
};
