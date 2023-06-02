component hint="cfWheels ShortCodes Plugin" output="false" mixin="global" {
    /**
     * @hint Constructor.
     */
    public function init() {
        this.version = "1.3,1.3.1,1.3.2,1.3.3,1.4.4,1.4.5";
        application.shortcodes = {};
        return this;
    }

    /********************* public ****************************/

    /**
     * @hint Register shortcodes
     */
    public void function addShortcode(required string code, required function callback) {
        application.shortcodes[code] = callback;
    }

    /**
     * @hint Process content with shortcodes
     */
    public string function processShortcodes(string content) {
        // Strip potential problematic HTML entities caused by RTEs
        content = replace(content, "&nbsp;", " ", "all");
        content = reReplaceNoCase(content, getRegex(), processTag, "all");
        return content;
    }

    /**
     * @hint Return Shortcodes
     */
    public string function returnShortcodes() {
        var result = "";
        if (structKeyExists(application, "shortcodes")) {
            result = "";
            for (var code in application.shortcodes) {
                result &= "[" & code & "]<br />";
                result &= writeDump(application.shortcodes[code]);
            }
        } else {
            result = "No shortcodes available - application.shortcodes doesn't exist";
        }
        return result;
    }

    /**
     * @hint Get regex pattern for shortcodes
     */
    private string function getRegex() {
        var versions = listToArray(this.version);
        var pattern = "";
        for (var version in versions) {
            if (len(pattern)) {
                pattern &= "|";
            }
            pattern &= "\[shortcode_" & version & "](.*?)\[\/shortcode_" & version & "]";
        }
        return pattern;
    }

    /**
     * @hint Process shortcode tag
     */
    private string function processTag(match) {
        var shortcode = match[1];
        var callback = application.shortcodes[shortcode];
        if (isDefined("callback") && isFunction(callback)) {
            return callback();
        } else {
            return "";
        }
    }
}

/********************* internal ****************************/

/**
 * @hint private get regex
 */
private string function getRegex() {
    return '(.?)\[(#structKeyList(application.shortcodes, "|")#)\b(.*?)(?:(\/))?\](?:(.+?)\[\/\2\])?(.?)';
}

/**
 * @hint private process tag
 */
private string function processTag(array parts) {
    if (parts[2] EQ '[' and parts[7] EQ ']') {
        return mid(parts[1], 2, len(parts[1]) - 2);
    }
    return parts[2] & invokeTag(parts[3], parseAttributes(parts[4]), parts[6]) & parts[7];
}

/**
 * @hint private invoke tag
 */
private string function invokeTag(string tag, struct attributes, string content) {
    var o = "";
    if (isCustomFunction(application.shortcodes[tag])) {
        o = application.shortcodes[tag];
        return o(attributes, content, tag);
    } else {
        // leave cfcs out
    }
}

/**
 * @hint private parse attributes
 */
private struct function parseAttributes(string text) {
    var attrs = {};
    var tokens = [];
    var si = "";
    var qi = "";
    var t = "";
    try {
        if (trim(text) EQ "") {
            return attrs;
        }
        text = trim(reReplace(text, "[\xA0\x200b]+", " ", "all"));
        while (true) {
            si = find(" ", text);
            qi = reFind("['\"]", text);
            if (si EQ 0 AND qi EQ 0) {
                if (trim(text) NEQ "") {
                    arrayAppend(tokens, trim(text));
                }
                break;
            } else if (si GT 0 AND (qi EQ 0 OR si LT qi)) {
                arrayAppend(tokens, trim(mid(text, 1, si)));
                text = trim(removeChars(text, 1, si));
            } else {
                t = trim(mid(text, 1, qi - 1)) & mid(text, qi + 1, find(mid(text, qi, 1), text, qi + 1) - qi - 1);
                arrayAppend(tokens, t);
                text = trim(removeChars(text, 1, len(t) + 2));
            }
        }
        for (var i = 1; i LTE arrayLen(tokens); i++) {
            var t = tokens[i];
            if (reFind('^\w+=', t) EQ 1) {
                attrs[listFirst(t, "=")] = listRest(t, "=");
            } else {
                attrs[i] = t;
            }
        }
        return attrs;
    } catch (any e) {
        // Handle any error that occurs during attribute parsing
        // You can add your own error handling logic here
        return {};
    }
}
} catch (any e) {
    // Silently fail: if we throw an error here, it can get to the point where the page is uneditable. Better to output nothing.
    // This assumes all your attr have a default.
    return {};
}

return attrs;
}

/**
 * @hint private regex replace callback
 */
private string function REReplaceCallback(string string, string pattern, function callback, string scope = "all") {
    var start = 1;
    var match = "";
    var parts = [];
    var replace = "";
    var l = 0;
    while (true) {
        match = reFind(pattern, string, start, true);
        if (match.pos[1] EQ 0) {
            break;
        }
        parts = [];
        l = arrayLen(match.pos);
        for (var i = 1; i LTE l; i++) {
            if (match.pos[i] EQ 0) {
                arrayAppend(parts, "");
            } else {
                arrayAppend(parts, mid(string, match.pos[i], match.len[i]));
            }
        }
        replace = callback(parts);
        start = start + len(replace);
        string = mid(string, 1, match.pos[1] - 1) & replace & removeChars(string, 1, match.pos[1] + match.len[1] - 1);
        if (scope EQ "one") {
            break;
        }
    }
    return string;
}
