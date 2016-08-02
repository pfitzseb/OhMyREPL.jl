module SyntaxHighlighter

using Compat

using Tokenize
using Tokenize.Tokens
import Tokenize.Tokens: Token, kind, exactkind, iskeyword

using ...ANSICodes
import ...ANSICodes: ANSIToken, ANSIValue, update!

import PimpMyREPL: add_pass!, PASS_HANDLER

type ColorScheme
    symbol::ANSIToken
    comment::ANSIToken
    string::ANSIToken
    call::ANSIToken
    op::ANSIToken
    keyword::ANSIToken
    text::ANSIToken
    function_def::ANSIToken
    error::ANSIToken
    argdef::ANSIToken
end

ColorScheme() = ColorScheme([ANSIToken() for i in 1:length(fieldnames(ColorScheme))]...)

type SyntaxHighlighterSettings
    colorscheme::ColorScheme
end
SyntaxHighlighterSettings() = SyntaxHighlighterSettings(ColorScheme())

SYNTAX_HIGHLIGHTER_SETTINGS = SyntaxHighlighterSettings()

# Try to represent the Monokai colorscheme.
function _create_monokai()
    monokai = ColorScheme()
    monokai.symbol = ANSIToken(foreground = :magenta)
    monokai.comment = ANSIToken(foreground = :dark_gray)
    monokai.string = ANSIToken(foreground = :yellow)
    monokai.call = ANSIToken(foreground = :blue)
    monokai.op = ANSIToken(foreground = :light_red)
    monokai.keyword = ANSIToken(foreground = :red)
    monokai.text = ANSIToken(foreground = :default)
    monokai.function_def = ANSIToken(foreground = :green)
    monokai.error = ANSIToken(foreground = :default)
    monokai.argdef = ANSIToken(foreground = :light_blue, italics = :true)
    return monokai
end

MONOKAI = _create_monokai()
SYNTAX_HIGHLIGHTER_SETTINGS.colorscheme = MONOKAI

add_pass!(PASS_HANDLER, "SyntaxHighlighter", SYNTAX_HIGHLIGHTER_SETTINGS, false)

@compat function (highlighter::SyntaxHighlighterSettings)(ansitokens::Vector{ANSIToken}, tokens::Vector{Token}, cursorpos::Int)
    cscheme = highlighter.colorscheme
    prev_t = Tokens.Token()
    for (i, t) in enumerate(tokens)
        if exactkind(prev_t) == Tokens.DECLARATION
            update!(ansitokens[i-1], cscheme.argdef)
            update!(ansitokens[i], cscheme.argdef)
        elseif kind(t) == Tokens.IDENTIFIER && exactkind(prev_t) == Tokens.COLON
            update!(ansitokens[i-1], cscheme.symbol)
            update!(ansitokens[i], cscheme.symbol)
        elseif iskeyword(kind(t))
            if kind(t) == Tokens.TRUE || kind(t) == Tokens.FALSE
                update!(ansitokens[i], cscheme.symbol)
            else
                update!(ansitokens[i], cscheme.keyword)
            end
        elseif kind(t) == Tokens.STRING || kind(t) == Tokens.TRIPLE_STRING || kind(t) == Tokens.CHAR
            update!(ansitokens[i], cscheme.string)
        elseif Tokens.isoperator(kind(t))
            update!(ansitokens[i], cscheme.op)
        elseif kind(t) == Tokens.COMMENT
            update!(ansitokens[i], cscheme.comment)
        else
            update!(ansitokens[i], cscheme.text)
        end
        prev_t = t
    end
    return
end

end
