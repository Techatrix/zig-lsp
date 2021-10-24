const std = @import("std");
const common = @import("./common.zig");

/// JSONRPC request
pub const Request = struct {
    jsonrpc: []const u8 = "2.0",
    id: common.RequestId,
    method: []const u8,
    params: RequestParams,

    fn fromTarget(target: RequestParseTarget) Request {
        inline for (std.meta.fields(RequestParseTarget)) |field, i| {
            if (@enumToInt(target) == i) {
                return .{
                    .id = @field(target, field.name).id,
                    .method = @field(target, field.name).method,
                    .params = @unionInit(RequestParams, field.name, @field(target, field.name).params),
                };
            }
        }

        unreachable;
    }

    pub fn parse(allocator: *std.mem.Allocator, buf: []const u8) std.json.ParseError(RequestParseTarget)!Request {
        return fromTarget(try std.json.parse(RequestParseTarget, &std.json.TokenStream.init(buf), .{
            .allocator = allocator,
            .ignore_unknown_fields = true,
        }));
    }
};

pub const RequestParams = union(enum) {
    initialize: InitializeParams,
    didChangeWorkspaceFolders: DidChangeWorkspaceFoldersParams,
};

/// Params of a request (params)
pub const RequestParseTarget = union(enum) {
    initialize: RequestParamsify(InitializeParams, "initialize"),
    didChangeWorkspaceFolders: RequestParamsify(DidChangeWorkspaceFoldersParams, "workspace/didChangeWorkspaceFolders"),
};

fn RequestParamsify(comptime T: type, comptime method_name: []const u8) type {
    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &[3]std.builtin.TypeInfo.StructField{
            .{
                .name = "method",
                .field_type = []const u8,
                .default_value = method_name,
                .is_comptime = true,
                .alignment = 0,
            },
            .{
                .name = "id",
                .field_type = common.RequestId,
                .default_value = null,
                .is_comptime = false,
                .alignment = 0,
            },
            .{
                .name = "params",
                .field_type = T,
                .default_value = null,
                .is_comptime = false,
                .alignment = 0,
            },
        },
        .decls = &.{},
        .is_tuple = false,
    } });
}

// Client init, capabilities, metadata

/// [Docs](https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#semanticTokensClientCapabilities)
pub const SemanticTokensClientCapabilities = struct {
    dynamicRegistration: bool = false,

    /// The token types that the client supports.
    tokenTypes: []const []const u8,

    /// The token modifiers that the client supports.
    tokenModifiers: []const []const u8,

    /// The formats the clients supports.
    formats: []const []const u8,

    /// Whether the client supports tokens that can overlap each other.
    overlappingTokenSupport: bool = false,

    /// Whether the client supports tokens that can span multiple lines.
    multilineTokenSupport: bool = false,
};

pub const ClientCapabilities = struct {
    workspace: ?struct {
        workspaceFolders: bool = false,
    },
    textDocument: ?struct {
        semanticTokens: ?SemanticTokensClientCapabilities = null,
        hover: ?struct {
            contentFormat: []const []const u8 = &.{},
        },
        completion: ?struct {
            completionItem: ?struct {
                snippetSupport: bool = false,
                documentationFormat: []const []const u8 = &.{},
            },
        },
    },
    offsetEncoding: []const []const u8 = &.{},
};

pub const InitializeParams = struct {
    capabilities: ClientCapabilities,
    workspaceFolders: ?[]const common.WorkspaceFolder,
};

pub const DidChangeWorkspaceFoldersParams = struct {
    event: struct {
        added: []const common.WorkspaceFolder,
        removed: []const common.WorkspaceFolder,
    },
};

pub const OpenDocument = struct {
    comptime method: []const u8 = "textDocument/didOpen",

    params: struct {
        textDocument: struct {
            /// The text document's URI.
            uri: []const u8,

            /// The text document's language identifier.
            languageId: []const u8,

            /// The version number of this document (it will increase after each
            /// change, including undo/redo).
            version: i32,

            /// The content of the opened text document.
            text: []const u8,
        },
    },
};

pub const TextDocumentIdentifier = struct {
    uri: []const u8,
};

pub const ChangeDocument = struct {
    comptime method: []const u8 = "textDocument/didChange",

    params: struct {
        textDocument: TextDocumentIdentifier,
        contentChanges: std.json.Value,
    },
};

const TextDocumentIdentifierRequestParams = struct {
    textDocument: TextDocumentIdentifier,
};

pub const TextDocumentSaveReason = enum(i64) {
    /// Manually triggered, e.g. by the user pressing save, by starting
    /// debugging, or by an API call.
    manual = 1,

    /// Automatic after a delay.
    after_delay = 2,

    /// When the editor lost focus.
    focus_out = 3,

    usingnamespace common.EnumStringify;
};

pub const SaveDocument = struct {
    comptime method: []const u8 = "textDocument/willSave",

    params: struct {
        textDocument: TextDocumentIdentifier,
        reason: TextDocumentSaveReason,
    },
};

pub const CloseDocument = struct {
    comptime method: []const u8 = "textDocument/didClose",

    params: TextDocumentIdentifierRequestParams,
};

pub const SemanticTokensFull = struct {
    params: TextDocumentIdentifierRequestParams,
};

const TextDocumentIdentifierPositionRequest = struct {
    params: struct {
        textDocument: TextDocumentIdentifier,
        position: common.Position,
    },
};

pub const SignatureHelp = struct {
    comptime method: []const u8 = "textDocument/signatureHelp",

    params: struct {
        textDocument: TextDocumentIdentifier,
        position: common.Position,
        context: ?struct {
            triggerKind: enum(u32) {
                invoked = 1,
                trigger_character = 2,
                content_change = 3,
            },
            triggerCharacter: ?[]const u8,
            isRetrigger: bool,
            activeSignatureHelp: ?common.SignatureHelp,
        },
    },
};

pub const Completion = TextDocumentIdentifierPositionRequest;
pub const GotoDefinition = TextDocumentIdentifierPositionRequest;
pub const GotoDeclaration = TextDocumentIdentifierPositionRequest;
pub const Hover = TextDocumentIdentifierPositionRequest;
pub const DocumentSymbols = struct {
    params: TextDocumentIdentifierRequestParams,
};
pub const Formatting = struct {
    params: TextDocumentIdentifierRequestParams,
};
pub const Rename = struct {
    params: struct {
        textDocument: TextDocumentIdentifier,
        position: common.Position,
        newName: []const u8,
    },
};

pub const References = struct {
    params: struct {
        textDocument: TextDocumentIdentifier,
        position: common.Position,
        context: struct {
            includeDeclaration: bool,
        },
    },
};
