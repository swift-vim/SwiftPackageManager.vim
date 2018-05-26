# The primary function of these utils is to support the iCompleteMe compatible
# DiagnosticUI.

import vim
import os
import json

# FIXME: Remove this
PY2 = True


def CurrentLineAndColumn():
    """Returns the 0-based current line and 0-based current column."""
    # See the comment in CurrentColumn about the calculation for the line and
    # column number
    line, column = vim.current.window.cursor
    line -= 1
    return line, column


def SetLocationList(diagnostics):
    """Populate the location list with diagnostics. Diagnostics should be in
    qflist format; see ":h setqflist" for details."""
    vim.eval('setloclist( 0, {0} )'.format(json.dumps(diagnostics)))


def BufferModified(buffer_object):
    return bool(int(GetBufferOption(buffer_object, 'mod')))


def GetBufferNumberForFilename(filename, open_file_if_needed=True):
    return GetIntValue(u"bufnr('{0}', {1})".format(
        EscapeForVim(os.path.realpath(filename)),
        int(open_file_if_needed)))


def GetCurrentBufferFilepath():
    return GetBufferFilepath(vim.current.buffer)


def BufferIsVisible(buffer_number):
    if buffer_number < 0:
        return False
    window_number = GetIntValue("bufwinnr({0})".format(buffer_number))
    return window_number != -1


def GetBufferFilepath(buffer_object):
    if buffer_object.name:
        return buffer_object.name
    # Buffers that have just been created by a command like :enew don't have any
    # buffer name so we use the buffer number for that.
    return os.path.join(GetCurrentDirectory(), str(buffer_object.number))


def PlaceSign(sign_id, line_num, buffer_num, is_error=True):
    # libclang can give us diagnostics that point "outside" the file; Vim borks
    # on these.
    if line_num < 1:
        line_num = 1

    sign_name = 'IcmError' if is_error else 'IcmWarning'
    vim.command('sign place {0} name={1} line={2} buffer={3}'.format(
        sign_id, sign_name, line_num, buffer_num))


def PlaceDummySign(sign_id, buffer_num, line_num):
    if buffer_num < 0 or line_num < 0:
        return
    vim.command('sign define icm_dummy_sign')
    vim.command(
        'sign place {0} name=icm_dummy_sign line={1} buffer={2}'.format(
            sign_id,
            line_num,
            buffer_num,
        )
    )


def UnplaceSignInBuffer(buffer_number, sign_id):
    if buffer_number < 0:
        return
    vim.command(
        'try | exec "sign unplace {0} buffer={1}" | catch /E158/ | endtry'.format(
            sign_id, buffer_number))


def UnPlaceDummySign(sign_id, buffer_num):
    if buffer_num < 0:
        return
    vim.command('sign undefine icm_dummy_sign')

    vim.command('sign unplace {0} buffer={1}'.format(sign_id, buffer_num))


def EscapeForVim(text):
    return ToUnicode(text.replace("'", "''"))


# Type helpers
def VariableExists(variable):
    return GetBoolValue("exists( '{0}' )".format(EscapeForVim(variable)))


def SetVariableValue(variable, value):
    vim.command("let {0} = {1}".format(variable, json.dumps(value)))


def GetVariableValue(variable):
    return vim.eval(variable)


def GetBoolValue(variable):
    return bool(int(vim.eval(variable)))


def GetIntValue(variable):
    return int(vim.eval(variable))


def AddDiagnosticSyntaxMatch(line_num,
                             column_num,
                             line_end_num=None,
                             column_end_num=None,
                             is_error=True):
    """Highlight a range in the current window starting from
    (|line_num|, |column_num|) included to (|line_end_num|, |column_end_num|)
    excluded. If |line_end_num| or |column_end_num| are not given, highlight the
    character at (|line_num|, |column_num|). Both line and column numbers are
    1-based. Return the ID of the newly added match."""
    group = 'IcmErrorSection' if is_error else 'IcmWarningSection'

    line_num, column_num = LineAndColumnNumbersClamped(line_num, column_num)

    if not line_end_num or not column_end_num:
        return GetIntValue(
            "matchadd('{0}', '\%{1}l\%{2}c')".format(group, line_num, column_num))

    # -1 and then +1 to account for column end not included in the range.
    line_end_num, column_end_num = LineAndColumnNumbersClamped(
        line_end_num, column_end_num - 1)
    column_end_num += 1

    return GetIntValue(
        "matchadd('{0}', '\%{1}l\%{2}c\_.\\{{-}}\%{3}l\%{4}c')".format(
            group, line_num, column_num, line_end_num, column_end_num))


# Clamps the line and column numbers so that they are not past the contents of
# the buffer. Numbers are 1-based byte offsets.
def LineAndColumnNumbersClamped(line_num, column_num):
    new_line_num = line_num
    new_column_num = column_num

    max_line = len(vim.current.buffer)
    if line_num and line_num > max_line:
        new_line_num = max_line

    max_column = len(vim.current.buffer[new_line_num - 1])
    if column_num and column_num > max_column:
        new_column_num = max_column

    return new_line_num, new_column_num


def PostVimMessage(message, warning=True, truncate=False):
    """Display a message on the Vim status line. By default, the message is
    highlighted and logged to Vim command-line history (see :h history).
    Unset the |warning| parameter to disable this behavior. Set the |truncate|
    parameter to avoid hit-enter prompts (see :h hit-enter) when the message is
    longer than the window width."""
    echo_command = 'echom' if warning else 'echo'

    # Displaying a new message while previous ones are still on the status line
    # might lead to a hit-enter prompt or the message appearing without a
    # newline so we do a redraw first.
    vim.command('redraw')

    if warning:
        vim.command('echohl WarningMsg')

    message = ToUnicode(message)

    if truncate:
        vim_width = GetIntValue('&columns')

        message = message.replace('\n', ' ')
        if len(message) > vim_width:
            message = message[: vim_width - 4] + '...'

        old_ruler = GetIntValue('&ruler')
        old_showcmd = GetIntValue('&showcmd')
        vim.command('set noruler noshowcmd')

        vim.command("{0} '{1}'".format(echo_command,
                                       EscapeForVim(message)))

        SetVariableValue('&ruler', old_ruler)
        SetVariableValue('&showcmd', old_showcmd)
    else:
        for line in message.split('\n'):
            vim.command("{0} '{1}'".format(echo_command,
                                           EscapeForVim(line)))

    if warning:
        vim.command('echohl None')


def ClearIcmSyntaxMatches():
    matches = VimExpressionToPythonType('getmatches()')
    for match in matches:
        if match['group'].startswith('Icm'):
            vim.eval('matchdelete({0})'.format(match['id']))


def VimExpressionToPythonType(vim_expression):
    """Returns a Python type from the return value of the supplied Vim expression.
    If the expression returns a list, dict or other non-string type, then it is
    returned unmodified. If the string return can be converted to an
    integer, returns an integer, otherwise returns the result converted to a
    Unicode string."""

    result = vim.eval(vim_expression)
    if not (isinstance(result, str) or isinstance(result, bytes)):
        return result

    try:
        return int(result)
    except ValueError:
        return ToUnicode(result)


# Utils

def ToUnicode(value):
    if not value:
        return str()
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        # All incoming text should be utf8
        return str(value, 'utf8')
    return str(value)


# When lines is an iterable of all strings or all bytes, equivalent to
#   '\n'.join( ToUnicode( lines ) )
# but faster on large inputs.
def JoinLinesAsUnicode(lines):
    try:
        first = next(iter(lines))
    except StopIteration:
        return str()

    if isinstance(first, str):
        return ToUnicode('\n'.join(lines))
    if isinstance(first, bytes):
        return ToUnicode(b'\n'.join(lines))
    raise ValueError('lines must contain either strings or bytes.')


def GetCurrentDirectory():
    """Returns the current directory as an unicode object. If the current
    directory does not exist anymore, returns the temporary folder instead."""
    try:
        if PY2:
            return os.getcwdu()
        return os.getcwd()
    # os.getcwdu throws an OSError exception when the current directory has been
    # deleted while os.getcwd throws a FileNotFoundError, which is a subclass of
    # OSError.
    except OSError:
        return tempfile.gettempdir()
