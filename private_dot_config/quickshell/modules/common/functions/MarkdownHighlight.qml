pragma Singleton
import Quickshell

/**
 * Markdown parser with syntax highlighting for code blocks.
 * Converts markdown to HTML with proper styling for Qt RichText.
 */
Singleton {
    id: root

    readonly property var languages: {
        const sh = {
            keywords: /\b(if|then|else|elif|fi|case|esac|for|while|do|done|in|function|select|until|return|exit|break|continue|local|export|readonly|declare|typeset|unset|shift|source)\b/g,
            builtins: /\b(echo|cd|pwd|ls|cat|grep|sed|awk|find|xargs|sort|uniq|head|tail|wc|cut|tr|tee|diff|chmod|chown|mkdir|rm|cp|mv|ln|touch|kill|ps|top|df|du|tar|gzip|gunzip|zip|unzip|curl|wget|ssh|scp|git|sudo|apt|yum|pacman|dnf|npm|pip|python|node|make|gcc|docker|systemctl)\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /#.*/g,
            variables: /\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?|\$[0-9@#?!$*-]/g,
            operators: /[|&;><]+|&&|\|\|/g,
            numbers: /\b\d+\b/g
        };
        const javascript = {
            keywords: /\b(async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|of|return|static|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b/g,
            builtins: /\b(console|window|document|Math|JSON|Object|Array|String|Number|Boolean|Date|RegExp|Error|Promise|Map|Set|Symbol|Proxy|Reflect)\b/g,
            strings: /(["'`])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*\b/g,
            functions: /\b([a-zA-Z_$][a-zA-Z0-9_$]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:]+/g
        };
        const python = {
            keywords: /\b(and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|True|False|None)\b/g,
            builtins: /\b(print|len|range|str|int|float|list|dict|set|tuple|bool|type|open|input|map|filter|zip|enumerate|sorted|reversed|sum|min|max|abs|round|any|all|isinstance|hasattr|getattr|setattr|super|property|classmethod|staticmethod)\b/g,
            strings: /("""[\s\S]*?"""|'''[\s\S]*?'''|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g,
            comments: /#.*/g,
            numbers: /\b\d+\.?\d*\b/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~@:]+/g
        };
        const rust = {
            keywords: /\b(as|async|await|break|const|continue|crate|dyn|else|enum|extern|false|fn|for|if|impl|in|let|loop|match|mod|move|mut|pub|ref|return|self|Self|static|struct|super|trait|true|type|unsafe|use|where|while)\b/g,
            builtins: /\b(Option|Result|Some|None|Ok|Err|Vec|String|Box|Rc|Arc|Cell|RefCell|HashMap|HashSet|BTreeMap|BTreeSet|println|print|format|panic|assert|debug_assert)\b/g,
            strings: /(r#*"[\s\S]*?"#*|"(?:[^"\\]|\\.)*")/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*(?:_\d+)*(?:u8|u16|u32|u64|u128|usize|i8|i16|i32|i64|i128|isize|f32|f64)?\b/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:;,]+|->|=>/g
        };
        const go = {
            keywords: /\b(break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|interface|map|package|range|return|select|struct|switch|type|var)\b/g,
            builtins: /\b(append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover|true|false|nil|iota)\b/g,
            strings: /(["'`])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*\b/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:;,]+|:=|<-/g
        };
        const json = {
            strings: /"(?:[^"\\]|\\.)*"/g,
            numbers: /-?\b\d+\.?\d*(?:[eE][+-]?\d+)?\b/g,
            keywords: /\b(true|false|null)\b/g,
            punctuation: /[{}\[\]:,]/g
        };
        const yaml = {
            keywords: /\b(true|false|null|yes|no|on|off)\b/gi,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /#.*/g,
            numbers: /\b\d+\.?\d*\b/g,
            punctuation: /[:\-|>]/g
        };
        const css = {
            keywords: /@[a-z-]+\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\*[\s\S]*?\*\//g,
            numbers: /-?\b\d+\.?\d*(?:px|em|rem|%|vh|vw|s|ms)?\b/g,
            functions: /\b([a-zA-Z-]+)\s*(?=\()/g,
            punctuation: /[{};:,()]/g
        };
        const html = {
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /<!--[\s\S]*?-->/g,
            keywords: /<\/?[a-zA-Z][a-zA-Z0-9-]*|>/g,
            punctuation: /[<>\/=]/g
        };
        const sql = {
            keywords: /\b(SELECT|FROM|WHERE|AND|OR|NOT|IN|IS|NULL|AS|JOIN|LEFT|RIGHT|INNER|OUTER|ON|GROUP|BY|ORDER|ASC|DESC|LIMIT|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|DROP|ALTER|INDEX)\b/gi,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /--.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*\b/g,
            punctuation: /[(),;*]/g
        };
        const c = {
            keywords: /\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|inline)\b/g,
            builtins: /\b(printf|scanf|malloc|free|calloc|realloc|sizeof|strlen|strcpy|strcat|strcmp|memcpy|memset|fopen|fclose|NULL|stdin|stdout|stderr)\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*[fFlLuU]*\b|0x[0-9a-fA-F]+/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:]+|->|\+\+|--/g
        };
        const java = {
            keywords: /\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while|true|false|null)\b/g,
            builtins: /\b(System|String|Integer|Double|Float|Boolean|Object|Class|Exception|Thread|List|ArrayList|Map|HashMap|Set|HashSet|Arrays|Collections|Math)\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*[fFdDlL]?\b|0x[0-9a-fA-F]+/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:]+|\+\+|--/g
        };
        const lua = {
            keywords: /\b(and|break|do|else|elseif|end|false|for|function|goto|if|in|local|nil|not|or|repeat|return|then|true|until|while)\b/g,
            builtins: /\b(print|type|tonumber|tostring|pairs|ipairs|next|select|unpack|require|dofile|loadfile|assert|error|pcall|xpcall|coroutine|string|table|math|io|os)\b/g,
            strings: /\[(=*)\[[\s\S]*?\]\1\]|(["'])(?:(?!\2)[^\\]|\\.)*?\2/g,
            comments: /--\[(=*)\[[\s\S]*?\]\1\]|--.*/g,
            numbers: /\b\d+\.?\d*\b|0x[0-9a-fA-F]+/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%^#=<>~]+|\.\.\.?/g
        };
        const nix = {
            keywords: /\b(if|then|else|assert|with|let|in|rec|inherit|or|and)\b/g,
            builtins: /\b(import|builtins|true|false|null|throw|abort|baseNameOf|derivation|dirOf|fetchTarball|fetchurl|fetchGit|fromJSON|toJSON|toString|typeOf|isNull|isBool|isInt|isFloat|isString|isList|isAttrs|isFunction)\b/g,
            strings: /(''[\s\S]*?''|"(?:[^"\\]|\\.)*")/g,
            comments: /#.*/g,
            numbers: /\b\d+\.?\d*\b/g,
            variables: /\$\{[^}]+\}/g,
            punctuation: /[{}\[\]();:,=]/g
        };
        const qml = {
            keywords: /\b(import|property|signal|readonly|alias|function|if|else|for|while|do|switch|case|default|break|continue|return|try|catch|finally|throw|true|false|null|undefined|var|let|const|new|this|typeof|instanceof)\b/g,
            builtins: /\b(Qt|Item|Rectangle|Text|Image|MouseArea|Column|Row|ListView|Repeater|Component|Loader|Timer|Animation|NumberAnimation|PropertyAnimation|Behavior|State|Transition|Connections|Binding)\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*\b/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:]+/g
        };
        const zig = {
            keywords: /\b(align|allowzero|and|asm|async|await|break|catch|comptime|const|continue|defer|else|enum|errdefer|error|export|extern|fn|for|if|inline|noalias|nosuspend|null|or|orelse|packed|pub|resume|return|struct|suspend|switch|test|threadlocal|try|undefined|union|unreachable|var|volatile|while)\b/g,
            builtins: /\b(bool|f16|f32|f64|f128|i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize|void|anyerror|anyframe|anytype|anyopaque|c_int|c_uint|c_long|c_ulong|c_longlong|c_ulonglong|c_short|c_ushort|c_char|c_void|comptime_int|comptime_float|noreturn|type)\b/g,
            strings: /(["'])(?:(?!\1)[^\\]|\\.)*?\1/g,
            comments: /\/\/.*|\/\*[\s\S]*?\*\//g,
            numbers: /\b\d+\.?\d*\b|0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+/g,
            functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
            operators: /[+\-*/%=<>!&|^~?:]+|=>|\.\./g,
            variables: /@[a-zA-Z_][a-zA-Z0-9_]*/g
        };

        return {
            sh, bash: sh, zsh: sh, shell: sh,
            javascript, js: javascript, typescript: javascript, ts: javascript,
            python, py: python,
            rust, rs: rust,
            go, golang: go,
            json, yaml, yml: yaml,
            css,
            html, xml: html,
            sql,
            c, cpp: c, "c++": c, h: c, hpp: c,
            java, lua, nix, qml, zig
        };
    }

    /**
     * Escapes HTML special characters.
     */
    function escapeHtml(str) {
        if (typeof str !== 'string') return str;
        return str
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /**
     * Validates that all required colors are present.
     * @returns {string[]} Array of missing color names
     */
    function validateColors(colors) {
        const required = [
            'keyword', 'string', 'comment', 'number', 'function',
            'builtin', 'variable', 'operator', 'text',
            'codeBackground', 'codeBorder', 'inlineCodeBackground', 'linkColor'
        ];
        const missing = [];
        for (const key of required) {
            if (!colors || !colors[key]) {
                missing.push(key);
            }
        }
        return missing;
    }

    /**
     * Highlights code according to language rules.
     */
    function highlightCode(code, language, colors) {
        const lang = root.languages[language?.toLowerCase()];
        if (!lang) {
            return escapeHtml(code);
        }

        const replacements = [];

        const processPattern = (pattern, type) => {
            if (!pattern) return;
            let match;
            const regex = new RegExp(pattern.source, pattern.flags);
            while ((match = regex.exec(code)) !== null) {
                replacements.push({
                    start: match.index,
                    end: match.index + match[0].length,
                    text: match[0],
                    type: type
                });
            }
        };

        // Process in order of priority
        processPattern(lang.comments, 'comment');
        processPattern(lang.strings, 'string');
        processPattern(lang.keywords, 'keyword');
        processPattern(lang.builtins, 'builtin');
        processPattern(lang.functions, 'function');
        processPattern(lang.variables, 'variable');
        processPattern(lang.numbers, 'number');
        processPattern(lang.operators, 'operator');
        processPattern(lang.punctuation, 'punctuation');

        // Sort by position and remove overlapping matches
        replacements.sort((a, b) => a.start - b.start);

        const filtered = [];
        let lastEnd = 0;
        for (const rep of replacements) {
            if (rep.start >= lastEnd) {
                filtered.push(rep);
                lastEnd = rep.end;
            }
        }

        // Build result from back to front
        let highlighted = code;
        for (let i = filtered.length - 1; i >= 0; i--) {
            const rep = filtered[i];
            const color = colors[rep.type] || colors.text;
            if (color) {
                const before = highlighted.slice(0, rep.start);
                const after = highlighted.slice(rep.end);
                const escaped = escapeHtml(rep.text);
                highlighted = before + `<span style="color: ${color};">${escaped}</span>` + after;
            }
        }

        return highlighted;
    }

    /**
     * Converts markdown to HTML with syntax-highlighted code blocks.
     * @param {string} markdown - The markdown text to convert
     * @param {object} colors - Color configuration from theme
     * @returns {object} { html: string, missingColors: string[] }
     */
    function markdownToHtml(markdown, colors) {
        if (!markdown) return { html: '', missingColors: [] };

        const missingColors = validateColors(colors);
        const c = colors || {};

        let html = markdown;
        const codeBlocks = [];

        // Extract and process code blocks (placeholder uses markers that won't conflict with markdown)
        html = html.replace(/```(\w*)\n?([\s\S]*?)```/g, (match, lang, code) => {
            const placeholder = `\x00CODEBLOCK${codeBlocks.length}\x00`;
            const highlighted = highlightCode(code.trim(), lang || 'text', c);
            const langLabel = lang ? `<font color="${c.comment}" size="2">${escapeHtml(lang)}</font><br/>` : '';
            // Use table with bgcolor for Qt RichText compatibility
            codeBlocks.push(
                `<br/><table width="100%" cellpadding="10" cellspacing="0" bgcolor="${c.codeBackground}">` +
                `<tr><td>` +
                langLabel +
                `<pre style="margin: 0; white-space: pre-wrap;"><font color="${c.text}" face="monospace">${highlighted}</font></pre>` +
                `</td></tr></table><br/>`
            );
            return placeholder;
        });

        // Escape HTML FIRST (preserve code block placeholders)
        const parts = html.split(/(\x00CODEBLOCK\d+\x00)/);
        html = parts.map(part => {
            if (part.match(/^\x00CODEBLOCK\d+\x00$/)) {
                return part;
            }
            return escapeHtml(part);
        }).join('');

        // Process inline code AFTER escaping (Qt RichText doesn't support inline backgrounds, just use monospace + color)
        html = html.replace(/`([^`]+)`/g, (match, code) => {
            return `<font face="monospace" color="${c.builtin}">${code}</font>`;
        });

        // Process markdown formatting
        html = html.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
        html = html.replace(/__([^_]+)__/g, '<b>$1</b>');
        html = html.replace(/\*([^*]+)\*/g, '<i>$1</i>');
        html = html.replace(/_([^_]+)_/g, '<i>$1</i>');
        html = html.replace(/~~([^~]+)~~/g, '<s>$1</s>');
        html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, `<a href="$2"><font color="${c.linkColor}">$1</font></a>`);

        // Headers (Qt uses h1-h6 tags)
        html = html.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>');
        html = html.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>');
        html = html.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>');
        html = html.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>');
        html = html.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>');
        html = html.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>');

        // Horizontal rules
        html = html.replace(/^(---|\*\*\*|___)$/gm, '<hr/>');

        // Blockquotes
        html = html.replace(/^&gt;\s+(.+)$/gm, `<blockquote><font color="${c.comment}">$1</font></blockquote>`);

        // Lists
        html = html.replace(/^[-*+]\s+(.+)$/gm, '<li>$1</li>');
        html = html.replace(/^\d+\.\s+(.+)$/gm, '<li>$1</li>');

        // Line breaks
        html = html.replace(/\n/g, '<br/>');

        // Restore code blocks
        codeBlocks.forEach((block, i) => {
            html = html.replace(`\x00CODEBLOCK${i}\x00`, block);
        });

        return { html, missingColors };
    }
}
