pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common
import qs.services.ai

Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property Component aiModelComponent: AiModel {}
    property Component openRouterApiStrategy: OpenRouterApiStrategy {}

    readonly property string interfaceRole: "interface"
    readonly property string apiKeyEnvVar: "OPENROUTER_API_KEY"

    signal responseFinished()

    property string systemPrompt: "You are a helpful AI assistant integrated into a desktop shell. Be concise and helpful. Use markdown for formatting when appropriate. You have access to tools to control the desktop environment - use them when the user asks you to perform actions."

    // Available tools for the AI to call
    property var tools: [
        {
            "type": "function",
            "function": {
                "name": "toggle_theme_mode",
                "description": "Toggle between light and dark mode for the desktop environment. Use this when the user wants to switch, change, or toggle the theme/color mode.",
                "parameters": {
                    "type": "object",
                    "properties": {},
                    "required": []
                }
            }
        }
    ]

    property var toolHandlers: ({
        "toggle_theme_mode": function(args) {
            toolExecutor.command = [`${Directories.home}/scripts/switch-theme-mode`];
            toolExecutor.running = true;
            return { success: true, message: "Theme mode toggled successfully" };
        },
    })

    function executeTool(toolName, toolArgs) {
        if (root.toolHandlers[toolName]) {
            return root.toolHandlers[toolName](toolArgs);
        }
        return { success: false, message: "Unknown tool: " + toolName };
    }

    property var messageIDs: []
    property var messageByID: ({})

    property real temperature: 0.7
    property QtObject tokenCount: QtObject {
        property int input: -1
        property int output: -1
        property int total: -1
    }

    function idForMessage(message) {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    property var models: {
        "openrouter/auto": aiModelComponent.createObject(root, {
            "name": "Z",
            "icon": "dialog-information-symbolic",
            "description": "OpenRouter Auto-routes to the best model",
            "endpoint": "https://openrouter.ai/api/v1/chat/completions",
            "model": "z-ai/glm-4.7",
            "requires_key": true,
            "key_env_var": "OPENROUTER_API_KEY",
        })
    }

    property var modelList: Object.keys(root.models)
    property string currentModelId: modelList[0]

    property var apiStrategy: openRouterApiStrategy.createObject(root)

    property string requestScriptFilePath: "/tmp/quickshell/ai/request.sh"

    function shellEscape(str) {
        return str.replace(/'/g, "'\\''");
    }

    function addMessage(message, role) {
        if (message.length === 0) return;
        const aiMessage = aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
            "rawContent": message,
            "thinking": false,
            "done": true,
        });
        const id = idForMessage(aiMessage);
        let newMessageByID = Object.assign({}, root.messageByID);
        newMessageByID[id] = aiMessage;
        root.messageByID = newMessageByID;
        root.messageIDs = root.messageIDs.concat([id]);
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length) return;
        const id = root.messageIDs[index];
        root.messageIDs.splice(index, 1);
        root.messageIDs = [...root.messageIDs];
        delete root.messageByID[id];
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId) {
        modelId = modelId.toLowerCase();
        if (modelList.indexOf(modelId) !== -1) {
            currentModelId = modelId;
            const model = models[modelId];
            root.addMessage(`Model set to **${model.name}**`, root.interfaceRole);
        } else {
            root.addMessage("Invalid model. Available models:\n- " + modelList.join("\n- "), root.interfaceRole);
        }
    }

    function setTemperature(value) {
        if (isNaN(value) || value < 0 || value > 2) {
            root.addMessage("Temperature must be between 0 and 2", root.interfaceRole);
            return;
        }
        root.temperature = value;
        root.addMessage(`Temperature set to **${value}**`, root.interfaceRole);
    }

    function clearMessages() {
        root.messageIDs = [];
        root.messageByID = ({});
        root.tokenCount.input = -1;
        root.tokenCount.output = -1;
        root.tokenCount.total = -1;
    }

    function sendUserMessage(message) {
        root.addMessage(message, "user");
        requester.makeRequest();
    }

    FileView {
        id: requesterScriptFile
    }

    // Process for executing tools
    Process {
        id: toolExecutor
        running: false
        onRunningChanged: {
        }
    }

    // Pending tool calls to process
    property var pendingToolCalls: []

    function handleToolCalls(toolCalls) {
        if (!toolCalls || toolCalls.length === 0) return;

        let toolResults = [];
        for (let i = 0; i < toolCalls.length; i++) {
            const toolCall = toolCalls[i];
            const toolName = toolCall.function?.name;
            let toolArgs = {};
            try {
                toolArgs = JSON.parse(toolCall.function?.arguments || "{}");
            } catch (e) {
                console.error("[AI] Failed to parse tool arguments:", e);
            }

            const result = root.executeTool(toolName, toolArgs);
            toolResults.push({
                tool_call_id: toolCall.id,
                role: "tool",
                content: JSON.stringify(result)
            });
        }

        // Send tool results back to continue the conversation
        root.sendToolResults(toolResults);
    }

    function sendToolResults(toolResults) {
        for (let i = 0; i < toolResults.length; i++) {
            const result = toolResults[i];
            const aiMessage = aiMessageComponent.createObject(root, {
                "role": "tool",
                "content": result.content,
                "rawContent": result.content,
                "toolCallId": result.tool_call_id,
                "thinking": false,
                "done": true,
            });
            const id = idForMessage(aiMessage);
            let newMessageByID = Object.assign({}, root.messageByID);
            newMessageByID[id] = aiMessage;
            root.messageByID = newMessageByID;
            root.messageIDs = root.messageIDs.concat([id]);
        }

        requester.makeRequest();
    }

    Process {
        id: requester
        property list<string> baseCommand: ["bash"]
        property AiMessageData message
        property ApiStrategy currentStrategy

        function markDone() {
            requester.message.done = true;
            root.responseFinished();
        }

        function makeRequest() {
            const model = models[currentModelId];
            requester.currentStrategy = root.apiStrategy;
            requester.currentStrategy.reset();

            const endpoint = root.apiStrategy.buildEndpoint(model);
            const messageArray = root.messageIDs.map(id => root.messageByID[id]);
            const filteredMessageArray = messageArray.filter(message => message.role !== root.interfaceRole);
            const data = root.apiStrategy.buildRequestData(model, filteredMessageArray, root.systemPrompt, root.temperature, root.tools);

            let requestHeaders = {
                "Content-Type": "application/json",
            };

            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "rawContent": "",
                "thinking": true,
                "done": false,
            });
            const id = idForMessage(requester.message);
            let newMessageByID = Object.assign({}, root.messageByID);
            newMessageByID[id] = requester.message;
            root.messageByID = newMessageByID;
            root.messageIDs = root.messageIDs.concat([id]);

            let headerString = Object.entries(requestHeaders)
                .filter(([k, v]) => v && v.length > 0)
                .map(([k, v]) => `-H '${k}: ${v}'`)
                .join(' ');

            const authHeader = requester.currentStrategy.buildAuthorizationHeader(root.apiKeyEnvVar);

            const scriptShebang = "#!/usr/bin/env bash\n";
            const scriptContent = scriptShebang
                + `[ -f "$HOME/.tokens" ] && source "$HOME/.tokens"\n`
                + `mkdir -p /tmp/quickshell/ai\n`
                + `curl --no-buffer "${endpoint}"`
                + ` ${headerString}`
                + (authHeader ? ` ${authHeader}` : "")
                + ` --data '${root.shellEscape(JSON.stringify(data))}'`
                + "\n";

            const shellScriptPath = root.requestScriptFilePath;
            requesterScriptFile.path = Qt.resolvedUrl(shellScriptPath);
            requesterScriptFile.setText(scriptContent);
            requester.command = baseCommand.concat([shellScriptPath]);
            requester.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0) return;
                if (requester.message.thinking) requester.message.thinking = false;

                try {
                    const result = requester.currentStrategy.parseResponseLine(data, requester.message);

                    if (result.tokenUsage) {
                        root.tokenCount.input = result.tokenUsage.input;
                        root.tokenCount.output = result.tokenUsage.output;
                        root.tokenCount.total = result.tokenUsage.total;
                    }
                    if (result.finished) {
                        requester.markDone();
                        // Handle tool calls if present
                        if (result.toolCalls && result.toolCalls.length > 0) {
                            root.handleToolCalls(result.toolCalls);
                        }
                    }
                } catch (e) {
                    console.error("[AI] Error parsing response:", e);
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                if (data.length > 0) {
                    console.error("[AI] stderr:", data);
                }
            }
        }

        onRunningChanged: {
            if (!running && requester.message && !requester.message.done) {
                const finishResult = requester.currentStrategy.onRequestFinished(requester.message);
                requester.markDone();
            }
        }
    }
}
