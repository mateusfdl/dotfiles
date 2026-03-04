import QtQuick

ApiStrategy {
    property bool isReasoning: false
    property var pendingToolCalls: []

    function buildEndpoint(model: AiModel): string {
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools) {
        let formattedMessages = [
            {role: "system", content: systemPrompt}
        ];

        for (let i = 0; i < messages.length; i++) {
            const msg = messages[i];
            if (msg.role === "tool") {
                formattedMessages.push({
                    "role": "tool",
                    "tool_call_id": msg.toolCallId,
                    "content": msg.rawContent,
                });
            } else if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
                formattedMessages.push({
                    "role": "assistant",
                    "content": msg.rawContent || null,
                    "tool_calls": msg.toolCalls,
                });
            } else {
                formattedMessages.push({
                    "role": msg.role,
                    "content": msg.rawContent,
                });
            }
        }

        let baseData = {
            "model": model.model,
            "messages": formattedMessages,
            "stream": true,
            "temperature": temperature,
        };

        // Add tools if available
        if (tools && tools.length > 0) {
            baseData.tools = tools;
        }

        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(envVarName: string): string {
        return `-H "Authorization: Bearer \$\{${envVarName}\}"`;
    }

    function parseResponseLine(line, message) {
        let cleanData = line.trim();
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        if (!cleanData || cleanData.startsWith(":")) return {};
        if (cleanData === "[DONE]") {
            return { finished: true };
        }

        try {
            const dataJson = JSON.parse(cleanData);

            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            const delta = dataJson.choices?.[0]?.delta;
            const responseContent = delta?.content || dataJson.message?.content;
            const responseReasoning = delta?.reasoning || delta?.reasoning_content;
            const toolCallsDelta = delta?.tool_calls;

            if (toolCallsDelta && toolCallsDelta.length > 0) {
                for (let i = 0; i < toolCallsDelta.length; i++) {
                    const tc = toolCallsDelta[i];
                    const idx = tc.index ?? i;

                    while (pendingToolCalls.length <= idx) {
                        pendingToolCalls.push({ id: "", type: "function", function: { name: "", arguments: "" } });
                    }

                    // Accumulate tool call data
                    if (tc.id) pendingToolCalls[idx].id = tc.id;
                    if (tc.type) pendingToolCalls[idx].type = tc.type;
                    if (tc.function?.name) pendingToolCalls[idx].function.name += tc.function.name;
                    if (tc.function?.arguments) pendingToolCalls[idx].function.arguments += tc.function.arguments;
                }
            }

            if (responseContent && responseContent.length > 0) {
                if (isReasoning) {
                    isReasoning = false;
                    message.rawContent += "\n\n</think>\n\n";
                }
                message.content += responseContent;
                message.rawContent += responseContent;
            } else if (responseReasoning && responseReasoning.length > 0) {
                if (!isReasoning) {
                    isReasoning = true;
                    message.rawContent += "\n\n<think>\n\n";
                }
                message.rawContent += responseReasoning;
            }

            const finishReason = dataJson.choices?.[0]?.finish_reason;
            if (finishReason === "tool_calls") {
                message.toolCalls = pendingToolCalls.slice();
                return { finished: true, toolCalls: message.toolCalls };
            }

            if (dataJson.usage) {
                return {
                    tokenUsage: {
                        input: dataJson.usage.prompt_tokens ?? -1,
                        output: dataJson.usage.completion_tokens ?? -1,
                        total: dataJson.usage.total_tokens ?? -1
                    }
                };
            }

            if (dataJson.done || finishReason === "stop") {
                return { finished: true };
            }

        } catch (e) {
            console.log("[AI] OpenRouter: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }

        return {};
    }

    function onRequestFinished(message) {
        return {};
    }

    function reset() {
        isReasoning = false;
        pendingToolCalls = [];
    }
}
