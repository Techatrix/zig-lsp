const std = @import("std");
const json = @import("../json.zig");
const common = @import("common.zig");

/// Params of a response (result)
pub const ResponseParams = union(enum) {
    none: void,
    string: []const u8,
    number: i64,
    boolean: bool,

    signature_help: SignatureHelpResponse,
    completion_list: CompletionList,
    // location: Location,
    // hover: Hover,
    // document_symbols: []DocumentSymbol,
    // semantic_tokens_full: struct { data: []const u32 },
    // text_edits: []TextEdit,
    // locations: []Location,
    // workspace_edit: WorkspaceEdit,
    initialize_result: InitializeResult,
};

/// [Docs](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#errorCodes)
pub const ErrorCode = enum(i64) {
    usingnamespace common.EnumStringify(@This());

    parse_error = -32700,
    invalid_request = -32600,
    method_not_found = -32601,
    invalid_params = -32602,
    internal_error = -32603,

    /// Error code indicating that a server received a notification or
    /// request before the server has received the `initialize` request.
    server_not_initialized = -32002,
    unknown_error_code = -32001,

    /// This is the end range of JSON RPC reserved error codes.
    /// It doesn't denote a real error code.
    ///
    /// * Since 3.16.0
    jsonrpc_reserved_error_range_end = -32000,

    /// This is the start range of LSP reserved error codes.
    /// It doesn't denote a real error code.
    ///
    /// * Since 3.16.0
    lsp_reserved_error_range_start = -32899,

    /// A request failed but it was syntactically correct, e.g the
    /// method name was known and the parameters were valid. The error
    /// message should contain human readable information about why
    /// the request failed.
    ///
    /// * Since 3.17.0
    request_failed = -32803,

    /// The server cancelled the request. This error code should
    /// only be used for requests that explicitly support being
    /// server cancellable.
    ///
    /// @since 3.17.0
    server_cancelled = -32802,

    /// The server detected that the content of a document got
    /// modified outside normal conditions. A server should
    /// NOT send this error code if it detects a content change
    /// in it unprocessed messages. The result even computed
    /// on an older state might still be useful for the client.
    /// 
    /// If a client decides that a result is not of any use anymore
    /// the client should cancel the request.
    content_modified = -32801,

    /// The client has canceled a request and a server has detected
    /// the cancel.
    request_cancelled = -32800,

    _,
};

// TODO: object, array
pub const ResponseErrorData = union(enum) {
    string: []const u8,
    number: ErrorCode,
    boolean: bool,
};

pub const ResponseError = struct {
    /// A number indicating the error type that occurred.
    code: common.integer,

    /// A string providing a short description of the error.
    message: []const u8,

    /// A primitive or structured value that contains additional
    /// information about the error. Can be omitted.
    data: ?ResponseErrorData,
};

/// A Response Message sent as a result of a request.
/// If a request doesn’t provide a result value the receiver
/// of a request still needs to return a response message
/// to conform to the JSON RPC specification. The result
/// property of the ResponseMessage should be set to null
/// in this case to signal a successful request.
///
/// [Docs](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#responseMessage)
pub const ResponseMessage = struct {
    jsonrpc: []const u8 = "2.0",
    id: common.RequestId,

    /// The result of a request. This member is REQUIRED on success.
    /// This member MUST NOT exist if there was an error invoking the method.
    /// To make it not exist, use `.{ .none = {} }`.
    result: ?ResponseParams = null,

    /// The error object in case a request fails.
    @"error": ?ResponseError = null,
};

pub const SignatureInformation = struct {
    pub const ParameterInformation = struct {
        // TODO Can also send a pair of encoded offsets
        label: []const u8,
        documentation: ?common.MarkupContent,
    };

    label: []const u8,
    documentation: ?common.MarkupContent,
    parameters: ?[]const ParameterInformation,
    activeParameter: ?u32,
};

/// Signature help represents the signature of something
/// callable. There can be multiple signature but only one
/// active and only one active parameter.
///
/// [Docs](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureHelp)
pub const SignatureHelpResponse = struct {
    signatures: ?[]const SignatureInformation,
    activeSignature: ?u32,
    activeParameter: ?u32,
};

/// [Docs](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initializeResult)
pub const InitializeResult = struct {
    offsetEncoding: []const u8,
    capabilities: struct {
        signatureHelpProvider: struct {
            triggerCharacters: []const []const u8,
            retriggerCharacters: []const []const u8,
        },
        textDocumentSync: enum(u32) {
            none = 0,
            full = 1,
            incremental = 2,

            usingnamespace common.EnumStringify(@This());
        },
        renameProvider: bool,
        completionProvider: struct {
            resolveProvider: bool,
            triggerCharacters: []const []const u8,
        },
        documentHighlightProvider: bool,
        hoverProvider: bool,
        codeActionProvider: bool,
        declarationProvider: bool,
        definitionProvider: bool,
        typeDefinitionProvider: bool,
        implementationProvider: bool,
        referencesProvider: bool,
        documentSymbolProvider: bool,
        colorProvider: bool,
        documentFormattingProvider: bool,
        documentRangeFormattingProvider: bool,
        foldingRangeProvider: bool,
        selectionRangeProvider: bool,
        workspaceSymbolProvider: bool,
        rangeProvider: bool,
        documentProvider: bool,
        workspace: ?struct {
            workspaceFolders: ?struct {
                supported: bool,
                changeNotifications: bool,
            },
        },
        semanticTokensProvider: ?struct {
            full: bool,
            range: bool,
            legend: struct {
                tokenTypes: []const []const u8,
                tokenModifiers: []const []const u8,
            },
        } = null,
    },
    serverInfo: struct {
        name: []const u8,
        version: ?[]const u8 = null,
    },
};

pub const CompletionList = struct {
    isIncomplete: bool,
    items: []const CompletionItem,
};

pub const CompletionItem = struct {
    const Kind = enum(i64) {
        text = 1,
        method = 2,
        function = 3,
        constructor = 4,
        field = 5,
        variable = 6,
        class = 7,
        interface = 8,
        module = 9,
        property = 10,
        unit = 11,
        value = 12,
        @"enum" = 13,
        keyword = 14,
        snippet = 15,
        color = 16,
        file = 17,
        reference = 18,
        folder = 19,
        enum_member = 20,
        constant = 21,
        @"struct" = 22,
        event = 23,
        operator = 24,
        type_parameter = 25,

        pub fn jsonStringify(value: Kind, options: json.StringifyOptions, out_stream: anytype) !void {
            try json.stringify(@enumToInt(value), options, out_stream);
        }
    };

    label: []const u8,
    kind: Kind,
    textEdit: ?common.TextEdit = null,
    filterText: ?[]const u8 = null,
    insertText: []const u8 = "",
    insertTextFormat: ?common.InsertTextFormat = .plaintext,
    detail: ?[]const u8 = null,
    documentation: ?common.MarkupContent = null,
};
