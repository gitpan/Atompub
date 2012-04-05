#line 1
## no critic (PodSections,UseWarnings,Interpolation,EndWithOne,NoisyQuotes)

package B::Keywords;

use strict;

require Exporter;
*import = *import = \&Exporter::import;

use vars qw( @EXPORT_OK %EXPORT_TAGS );
@EXPORT_OK = qw( @Scalars @Arrays @Hashes @Filehandles @Symbols
                 @Functions @Barewords );
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use vars '$VERSION';
$VERSION = '1.12';

use vars '@Scalars';
@Scalars = (
    qw( $a
        $b
        $_ $ARG
        $& $MATCH
        $` $PREMATCH
        $' $POSTMATCH
        $+ $LAST_PAREN_MATCH
        $* $MULTILINE_MATCHING
        $. $INPUT_LINE_NUMBER $NR
        $/ $INPUT_RECORD_SEPARATOR $RS
        $| $OUTPUT_AUTO_FLUSH ), '$,', qw( $OUTPUT_FIELD_SEPARATOR $OFS
        $\ $OUTPUT_RECORD_SEPARATOR $ORS
        $" $LIST_SEPARATOR
        $; $SUBSCRIPT_SEPARATOR $SUBSEP
        ), '$#', qw( $OFMT
        $% $FORMAT_PAGE_NUMBER
        $= $FORMAT_LINES_PER_PAGE
        $- $FORMAT_LINES_LEFT
        $~ $FORMAT_NAME
        $^ $FORMAT_TOP_NAME
        $: $FORMAT_LINE_BREAK_CHARACTERS
        $? $CHILD_ERROR $^CHILD_ERROR_NATIVE
        $! $ERRNO $OS_ERROR
        $@ $EVAL_ERROR
        $$ $PROCESS_ID $PID
        $< $REAL_USER_ID $UID
        $> $EFFECTIVE_USER_ID $EUID ), '$(', qw( $REAL_GROUP_ID $GID ), '$)',
    qw(
        $EFFECTIVE_GROUP_ID $EGID
        $0 $PROGRAM_NAME
        $[
        $]
        $^A $ACCUMULATOR
        $^C $COMPILING
        $^D $DEBUGGING
        $^E $EXTENDED_OS_ERROR
        $^ENCODING
        $^F $SYSTEM_FD_MAX
        $^H
        $^I $INPLACE_EDIT
        $^L $FORMAT_FORMFEED
        $^M
        $^N
        $^O $OSNAME
        $^OPEN
        $^P $PERLDB
        $^R $LAST_REGEXP_CODE_RESULT
        $^RE_DEBUG_FLAGS
        $^RE_TRIE_MAXBUF
        $^S $EXCEPTIONS_BEING_CAUGHT
        $^T $BASETIME
        $^TAINT
        $^UNICODE
        $^UTF8LOCALE
        $^V $PERL_VERSION
        $^W $WARNING $^WARNING_BITS
        $^WIDE_SYSTEM_CALLS
        $^X $EXECUTABLE_NAME
        $ARGV
        ),
);

use vars '@Arrays';
@Arrays = qw(
    @+ $LAST_MATCH_END
    @- @LAST_MATCH_START
    @ARGV
    @INC
    @_
);

use vars '@Hashes';
@Hashes = qw(
    %OVERLOAD
    %!
    %^H
    %INC
    %ENV
    %SIG
);

use vars '@Filehandles';
@Filehandles = qw(
    *ARGV ARGV
    ARGVOUT
    STDIN
    STDOUT
    STDERR
);

use vars '@Functions';
@Functions = qw(
    __SUB__
    AUTOLOAD
    BEGIN
    DESTROY
    END
    INIT
    CHECK
    UNITCHECK
    abs
    accept
    alarm
    atan2
    bind
    binmode
    bless
    break
    caller
    chdir
    chmod
    chomp
    chop
    chown
    chr
    chroot
    close
    closedir
    connect
    cos
    crypt
    dbmclose
    dbmopen
    defined
    delete
    die
    dump
    each
    endgrent
    endhostent
    endnetent
    endprotoent
    endpwent
    endservent
    eof
    eval
    evalbytes
    exec
    exists
    exit
    fc
    fcntl
    fileno
    flock
    fork
    format
    formline
    getc
    getgrent
    getgrgid
    getgrnam
    gethostbyaddr
    gethostbyname
    gethostent
    getlogin
    getnetbyaddr
    getnetbyname
    getnetent
    getpeername
    getpgrp
    getppid
    getpriority
    getprotobyname
    getprotobynumber
    getprotoent
    getpwent
    getpwnam
    getpwuid
    getservbyname
    getservbyport
    getservent
    getsockname
    getsockopt
    glob
    gmtime
    goto
    grep
    hex
    index
    int
    ioctl
    join
    keys
    kill
    last
    lc
    lcfirst
    length
    link
    listen
    local
    localtime
    log
    lstat
    map
    mkdir
    msgctl
    msgget
    msgrcv
    msgsnd
    my
    next
    not
    oct
    open
    opendir
    ord
    our
    pack
    pipe
    pop
    pos
    print
    printf
    prototype
    push
    quotemeta
    rand
    read
    readdir
    readline
    readlink
    readpipe
    recv
    redo
    ref
    rename
    require
    reset
    return
    reverse
    rewinddir
    rindex
    rmdir
    say
    scalar
    seek
    seekdir
    select
    semctl
    semget
    semop
    send
    setgrent
    sethostent
    setnetent
    setpgrp
    setpriority
    setprotoent
    setpwent
    setservent
    setsockopt
    shift
    shmctl
    shmget
    shmread
    shmwrite
    shutdown
    sin
    sleep
    socket
    socketpair
    sort
    splice
    split
    sprintf
    sqrt
    srand
    stat
    state
    study
    substr
    symlink
    syscall
    sysopen
    sysread
    sysseek
    system
    syswrite
    tell
    telldir
    tie
    tied
    time
    times
    truncate
    uc
    ucfirst
    umask
    undef
    unlink
    unpack
    unshift
    untie
    use
    utime
    values
    vec
    wait
    waitpid
    wantarray
    warn
    write

    -r -w -x -o
    -R -W -X -O -e -z -s
    -f -d -l -p -S -b -c -t
    -u -g -k
    -T -B
    -M -A -C
);

use vars '@Barewords';
@Barewords = qw(
    __FILE__
    __LINE__
    __PACKAGE__
    __DATA__
    __END__
    CORE
    EQ
    GE
    GT
    LE
    LT
    NE
    NULL
    and
    cmp
    continue
    default
    do
    else
    elsif
    eq
    err
    exp
    for
    foreach
    ge
    given
    gt
    if
    le
    lock
    lt
    m
    ne
    no
    or
    package
    q
    qq
    qr
    qw
    qx
    s
    sub
    tr
    unless
    until
    when
    while
    x
    xor
    y
);

use vars '@Symbols';
@Symbols = ( @Scalars, @Arrays, @Hashes, @Filehandles, @Functions );

# This quote is blatantly copied from ErrantStory.com, Michael Poe's
# comic.
BEGIN { $^W = 0 }
"You know, when you stop and think about it, Cthulhu is a bit a Mary Sue isn't he?"

__END__
