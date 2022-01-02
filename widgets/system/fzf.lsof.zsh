#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"


# modes=("files" "grouped")
# toggles=("user_files" "all_files" "network_files" "sockets" "ports" "deleted")
# lsof | grep deleted
# If the strace/ltrace is overkill, consider inspecting the /proc/PID/fd folder. Each entry modification time will show the timestamp that the FD was created, effectively the open/connect/accept time:
# X_PID is the PID of the process to monitor/check
# ls -lt --time-style=full-iso /proc/$X_PID/fd

# TODO: ctrace:summary
FZF_ACTIONS=(
  "details"
  "cat"
  "kill"
  "kill:9"
  "ctrace"
  "ctrace:verbose"
  "ltrace"
  "iotrace"
)

FZF_ACTION_DESCRIPTIONS=(
  "output details about the selected file(es) and associated process(es)"
  "output the contents of the selected file(s)"
  "kill process(es) (SIGTERM) that have target file(s) open"
  "kill process(es) -9 (SIGKILL) that have target file(s) open"
  "ctrace process(es) (only errors) that have target file(s) open"
  "ctrace process(es) (all calls) that have target file(s) open"
  "ltrace process(es) that have target file(s) open"
  "iotrace process(es) that have target file(s) open"
)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}

_fzf-extra-opts() {
  opts="--query=\"!fzf $*\""
  # opts="${opts} --nth=1,2,3,-1"
  opts="${opts} --header-lines=1"
  # [ $RELOAD_ON_CHANGE -eq 1 ] && \
  #   opts="${opts},change:reload:'$source_command'"
  echo "$opts"
}


# COMMAND      PID    TID TASKCMD               USER   FD      TYPE             DEVICE  SIZE/OFF       NODE NAME
# lsof your_dir | awk '{for(i=9;i<=NF;++i)print $i}'
_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CMD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    item_user=$(echo "$item" | sed -E 's/\S+\s+\S+\s+//' | cut -d' ' -f1)
    is_root=$([[ "$item_user" == "root" ]] && echo 1 || echo 0)

    case "$action" in
      'kill')
        echo "kill $item_id $is_root"
        [ $is_root -eq 1 ] \
          && sudo kill $item_id  \
          || kill $item_id
        ;;
      'kill:9')
        echo "kill:9 $item_id $is_root"
        [ $is_root -eq 1 ] \
          && sudo kill -9 $item_id  \
          || kill -9 $item_id
        ;;
      'ctrace')
        echo "ctrace $item_id $is_root"
        [ $is_root -eq 1 ] \
          && sudo ctrace -p $item_id  \
          || ctrace -p $item_id
        # ctrace -f "lstat,open"
        ;;
      'ctrace:verbose')
        echo "ctrace:verbose $item_id $is_root"
        [ $is_root -eq 1 ] \
          && sudo ctrace -v -p $item_id  \
          || ctrace -v -p $item_id
        ;;
      'ltrace')
        echo "ltrace $item_id $is_root"
        [ $is_root -eq 1 ] \
          && sudo ltrace -p $item_id  \
          || ltrace -p $item_id
        ;;
     'iotrace')
        echo "iotrace $item_id"
        [ $is_root -eq 1 ] \
          && sudo iotrace -p $item_id | bat -lstrace -p \
          || iotrace -p $item_id | bat -lstrace -p
        ;;
      # 'iotrace:forked')
      #   ;;

    esac
  done
}

_fzf-prompt() {
  echo " lsof❯ "
}

_fzf-preview() {
  echo "These are my preview files: $1"
}

_fzf-source() {
  grc --colour=on -es -c conf.lsof  \
    lsof -w -u $USER  \
    | sed "s,$HOME,~,g"
    # | fzf --ansi --header-lines=1 \
    # | sed 's/^ *//' | cut -f1 -d' '
}


# _fzf-source
source "$FZF_LIB"

# mimetype path/to/file            # Print the MIME type of a given file:
# mimetype --brief path/to/file    # Display only the MIME type, and not the filename:
# mimetype --describe path/to/file # Display a description of the MIME type:
# mimetype --debug path/to/file    # Display debug information about how the MIME type was determined:
# mimetype --all path/to/file      # Display all the possible MIME types of a given file in confidence order:
# some_command | mimetype --stdin  # Determine the MIME type of stdin (does not check a filename):

# stat command
# Usage: /usr/bin/stat [OPTION]... FILE...
# Display file or file system status.
  # -L, --dereference     follow links
  # -f, --file-system     display file system status instead of file status
  #     --cached=MODE     specify how to use cached attributes; useful on remote file systems. See MODE below
  # -c  --format=FORMAT   use the specified FORMAT instead of the default; output a newline after each use of FORMAT
  #     --printf=FORMAT   like --format, but interpret backslash escapes, and do not output a mandatory trailing newline;
  #                       if you want a newline, include \n in FORMAT
  # -t, --terse           print the information in terse form

  # The valid format sequences for files (without --file-system):
  # %a   permission bits in octal (note '#' and '0' printf flags)
  # %A   permission bits and file type in human readable form
  # %b   number of blocks allocated (see %B)
  # %B   the size in bytes of each block reported by %b
  # %C   SELinux security context string
  # %d   device number in decimal
  # %D   device number in hex
  # %f   raw mode in hex
  # %F   file type
  # %g   group ID of owner
  # %G   group name of owner
  # %h   number of hard links
  # %i   inode number
  # %m   mount point
  # %n   file name
  # %N   quoted file name with dereference if symbolic link
  # %o   optimal I/O transfer size hint
  # %s   total size, in bytes
  # %t   major device type in hex, for character/block device special files
  # %T   minor device type in hex, for character/block device special files
  # %u   user ID of owner
  # %U   user name of owner
  # %w   time of file birth, human-readable; - if unknown
  # %W   time of file birth, seconds since Epoch; 0 if unknown
  # %x   time of last access, human-readable
  # %X   time of last access, seconds since Epoch
  # %y   time of last data modification, human-readable
  # %Y   time of last data modification, seconds since Epoch
  # %z   time of last status change, human-readable
  # %Z   time of last status change, seconds since Epoch

  # Valid format sequences for file systems:

  # %a   free blocks available to non-superuser
  # %b   total data blocks in file system
  # %c   total file nodes in file system
  # %d   free file nodes in file system
  # %f   free blocks in file system
  # %i   file system ID in hex
  # %l   maximum length of filenames
  # %n   file name
  # %s   block size (for faster transfers)
  # %S   fundamental block size (for block counts)
  # %t   file system type in hex
  # %T   file system type in human readable form
  # --terse is equivalent to the following FORMAT:
  # %n %s %b %f %u %g %D %i %h %t %T %X %Y %Z %W %o %C
  # --terse --file-system is equivalent to the following FORMAT:
  # %n %i %l %t %s %S %b %f %a %c %d


############
# LSOF OUTPUT
# Note: Root privileges (or sudo) is required to list files opened by others.

# sudo lsof -i4                   # To list all IPv4 network files:
# sudo lsof -i6                   # To list all IPv6 network files:
# lsof -i                         # To list all open sockets:
# lsof -Pnl +M -i4                # To list all listening ports:
# lsof -i TCP:80                  # To find which program is using the port 80:
# lsof -i@192.168.1.5             # To list all connections to a specific host:
# lsof <path>                     # To list all processes accessing a particular file/directory:
# lsof -u <username>              # To list all files open for a particular user:
# lsof -c <command>               # To list all files/network connections a command is using:
# lsof -p <pid>                   # To list all files a process has open:
# lsof -c process_or_command_name # List files opened by the given command or process:
# lsof -t path/to/file            # Only output the process ID (PID):
# lsof -iTCP:port -sTCP:LISTEN    # Find the process that is listening on a local TCP port:
# # (Particularly useful for finding which process(es) are using a mounted USB stick or CD/DVD.)
# lsof +f -- <mount-point>        # To list all files open mounted at /mount/point:

# Lsof  dynamically  sizes	 the output columns each time it runs, guaranteeing that each
# column is a minimum size.  It also guarantees that each column is separated  from  its predecessor by at least one space.

# -F f
# -N  -> selects all NFS files
# -R  -> PPID
# -g  -> PGID
# -K  -> shows individual tasks/threads
# +-L -> show file link counts
# +-r -> repeat mode
# +-w -> enable/suppress warning

#     COMMAND	  contains  the first nine characters of the name of the UNIX command associated with the process.
#       If a non-zero w value is specified to the +c w  option,	 the  column  contains the first w characters of the name of the UNIX
#       command associated with the process up to the limit of characters  supplied to  lsof  by the UNIX dialect.
#       If w is less than the length of the column title, ``COMMAND'', it  will  be raised to that length.
#       If  a zero w value is specified to the +c w option, the column contains all the characters of the name of the
#       UNIX command associated with the process.

#     PID	  is the Process IDentification number of the process.

#     TID	  is  the  task (thread) ID number, if task (thread) reporting is supported by the dialect and a task (thread) is  being  listed.
#         A blank TID column in Linux indicates a process - i.e., a non-task.

#     TASKCMD	  is the task command name.  Generally this will be the same as	 the  process named	 in  the  COMMAND column
#    	   The TASKCMD column width is subject to the same size limitation as the COMMAND column.

#     ZONE	  is  the Solaris 10 and higher zone name.  This column must be selected with the -z option.

#     SECURITY-CONTEXT is the SELinux security context.  This column must be selected with the  -Z option.

#     PPID	  is the Parent Process IDentification number of the  process.	 It  is	 only displayed when the -R option has been specified.

#     PGID	  is the process group IDentification number associated with the process.  It is only displayed when the -g option has been specified.

#     USER	  is the user ID number or login name of the user to  whom  the	 process  belongs,  usually  the	same as reported by ps(1).
#       However, on Linux USER is the user ID number or login that owns the directory  in  /proc  where	 lsof finds	 information  about  the process.
#       Usually that is the same value reported by ps(1), but may differ when the process has changed its  effective user	ID.
#       (See the -l option description for information on when a user ID number or login name is displayed.)

#     FD	  is the File Descriptor number of the file or:
#       cwd  current working directory;
#       Lnn  library references (AIX);
#       err  FD information error (see NAME column);
#       jld  jail directory (FreeBSD);
#       ltx  shared library text (code and data);
#       Mxx  hex memory-mapped type number xx.
#       m86  DOS Merge mapped file;
#       mem  memory-mapped file;
#       mmap memory-mapped device;
#       pd   parent directory;
#       rtd  root directory;
#       tr   kernel trace file (OpenBSD);
#       txt  program text (code and data);
#       v86  VP/ix mapped file  ;

#     FD is followed by one of these characters, describing the mode under	which the file is open:
#       r for read access;
#       w for write access;
#       u for read and write access;
#       space if mode unknown and no lock character follows;
#       `-' if mode unknown and lock character follows.

#     The  mode character is followed by one of these lock characters, describing the type of lock applied to the file:
#       N for a Solaris NFS lock of unknown type;
#       r for read lock on part of the file;
#       R for a read lock on the entire file;
#       w for a write lock on part of the file;
#       W for a write lock on the entire file;
#       u for a read and write lock of any length;
#       U for a lock of unknown type;
#       x for an SCO OpenServer Xenix lock on part  of the file;
#       X for an SCO OpenServer Xenix lock on the entire file;
#       space if there is no lock.

#     The  FD column contents constitutes a single field for parsing in post-proessing scripts.

#     TYPE	  is the type of the node associated with the file - e.g., GDIR, GREG,	VDIR, VREG, etc.
#       or ``IPv4'' for an IPv4 socket;
#       or  ``IPv6''	for  an open IPv6 network file - even if its address is IPv4, mapped in an IPv6 address;
#       or ``ax25'' for a Linux AX.25 socket;
#       or ``inet'' for an Internet domain socket;
#       or ``lla'' for a HP-UX link level access file;
#       or ``rte'' for an AF_ROUTE socket;
#       or ``sock'' for a socket of unknown domain;
#       or ``unix'' for a UNIX domain socket;
#       or ``x.25'' for an HP-UX x.25 socket;
#       or ``BLK'' for a block special file;
#       or ``CHR'' for a character special file;
#       or ``DEL'' for a Linux map file that has been deleted;
#       or ``DIR'' for a directory;
#       or ``DOOR'' for a VDOOR file;
#       or ``FIFO'' for a FIFO special file;
#       or ``KQUEUE'' for a BSD style kernel event queue file;
#       or ``LINK'' for a symbolic link file;
#       or ``MPB'' for a multiplexed block file;
#       or ``MPC'' for a multiplexed character file;
#       or ``NOFD'' for a Linux /proc/<PID>/fd directory that can't  be  opened  the  directory  path	appears in the NAME column, followed by an error message;
#       or ``PAS'' for a /proc/as file;
#       or ``PAXV'' for a /proc/auxv file;
#       or ``PCRE'' for a /proc/cred file;
#       or ``PCTL'' for a /proc control file;
#       or ``PCUR'' for the current /proc process;
#       or ``PCWD'' for a /proc current working directory;
#       or ``PDIR'' for a /proc directory;
#       or ``PETY'' for a /proc executable type (etype);
#       or ``PFD'' for a /proc file descriptor;
#       or ``PFDR'' for a /proc file descriptor directory;
#       or ``PFIL'' for an executable /proc file;
#       or ``PFPR'' for a /proc FP register set;
#       or ``PGD'' for a /proc/pagedata file;
#       or ``PGID'' for a /proc group notifier file;
#       or ``PIPE'' for pipes;
#       or ``PLC'' for a /proc/lwpctl file;
#       or ``PLDR'' for a /proc/lpw directory;
#       or ``PLDT'' for a /proc/ldt file;
#       or ``PLPI'' for a /proc/lpsinfo file;
#       or ``PLST'' for a /proc/lstatus file;
#       or ``PLU'' for a /proc/lusage file;
#       or ``PLWG'' for a /proc/gwindows file;
#       or ``PLWI'' for a /proc/lwpsinfo file;
#       or ``PLWS'' for a /proc/lwpstatus file;
#       or ``PLWU'' for a /proc/lwpusage file;
#       or ``PLWX'' for a /proc/xregs file;
#       or ``PMAP'' for a /proc map file (map);
#       or ``PMEM'' for a /proc memory image file;
#       or ``PNTF'' for a /proc process notifier file;
#       or ``POBJ'' for a /proc/object file;
#       or ``PODR'' for a /proc/object directory;
#       or ``POLP'' for an old format /proc light weight process file;
#       or ``POPF'' for an old format /proc PID file;
#       or ``POPG'' for an old format /proc page data file;
#       or ``PORT'' for a SYSV named pipe;
#       or ``PREG'' for a /proc register file;
#       or ``PRMP'' for a /proc/rmap file;
#       or ``PRTD'' for a /proc root directory;
#       or ``PSGA'' for a /proc/sigact file;
#       or ``PSIN'' for a /proc/psinfo file;
#       or ``PSTA'' for a /proc status file;
#       or ``PSXSEM'' for a POSIX semaphore file;
#       or ``PSXSHM'' for a POSIX shared memory file;
#       or ``PTS'' for a /dev/pts file;
#       or ``PUSG'' for a /proc/usage file;
#       or ``PW'' for a /proc/watch file;
#       or ``PXMP'' for a /proc/xmap file;
#       or ``REG'' for a regular file;
#       or ``SMT'' for a shared memory transport file;
#       or ``STSO'' for a stream socket;
#       or ``UNNM'' for an unnamed type file;
#       or ``XNAM'' for an OpenServer Xenix special file of unknown type;
#       or ``XSEM'' for an OpenServer Xenix semaphore file;
#       or ``XSD'' for an OpenServer Xenix shared data file;
#       or the four type number octets if the corresponding name isn't known          .

#     FILE-ADDR  contains the kernel file structure address when f has been specified to +f;

#     FCT	  contains the file reference count from the kernel file structure when c has been specified to +f;

#     FILE-FLAG  when	g  or G has been specified to +f, this field contains the contents of the f_flag[s]
#     member	 of  the  kernel  file	structure  and	the  kernel's per-process open file flags (if available);
#     `G' causes them to be displayed in hexadecimal; `g', as short-hand names; two lists may be  displayed	 with
#     entries  separated by commas, the lists separated by a semicolon (`;');
#     the first list may contain short-hand names for f_flag[s] values from the	 following table:

#       AIO	 asynchronous I/O (e.g., FAIO)
#       AP	 append
#       ASYN	 asynchronous I/O (e.g., FASYNC)
#       BAS	 block, test, and set in use
#       BKIU	 block if in use
#       BL	 use block offsets
#       BSK	 block seek
#       CA	 copy avoid
#       CIO	 concurrent I/O
#       CLON	 clone
#       CLRD	 CL read
#       CR	 create
#       DF	 defer
#       DFI	 defer IND
#       DFLU	 data flush
#       DIR	 direct
#       DLY	 delay
#       DOCL	 do clone
#       DSYN	 data-only integrity
#       DTY	 must be a directory
#       EVO	 event only
#       EX	 open for exec
#       EXCL	 exclusive open
#       FSYN	 synchronous writes
#       GCDF	 defer during unp_gc() (AIX)
#       GCMK	 mark during unp_gc() (AIX)
#       GTTY	 accessed via /dev/tty
#       HUP	 HUP in progress
#       KERN	 kernel
#       KIOC	 kernel-issued ioctl
#       LCK	 has lock
#       LG	 large file
#       MBLK	 stream message block
#       MK	 mark
#       MNT	 mount
#       MSYN	 multiplex synchronization
#       NATM	 don't update atime
#       NB	 non-blocking I/O
#       NBDR	 no BDRM check
#       NBIO	 SYSV non-blocking I/O
#       NBF	 n-buffering in effect
#       NC	 no cache
#       ND	 no delay
#       NDSY	 no data synchronization
#       NET	 network
#       NFLK	 don't follow links
#       NMFS	 NM file system
#       NOTO	 disable background stop
#       NSH	 no share
#       NTTY	 no controlling TTY
#       OLRM	 OLR mirror
#       PAIO	 POSIX asynchronous I/O
#       PP	 POSIX pipe
#       R	 read
#       RC	 file and record locking cache
#       REV	 revoked
#       RSH	 shared read
#       RSYN	 read synchronization
#       RW	 read and write access
#       SL	 shared lock
#       SNAP	 cooked snapshot
#       SOCK	 socket
#       SQSH	 Sequent shared set on open
#       SQSV	 Sequent SVM set on open
#       SQR	 Sequent set repair on open
#       SQS1	 Sequent full shared open
#       SQS2	 Sequent partial shared open
#       STPI	 stop I/O
#       SWR	 synchronous read
#       SYN	 file integrity while writing
#       TCPM	 avoid TCP collision
#       TR	 truncate
#       W	 write
#       WKUP	 parallel I/O synchronization
#       WTG	 parallel I/O synchronization
#       VH	 vhangup pending
#       VTXT	 virtual text
#       XL	 exclusive loc    k

#     the second list (after the semicolon) may contain short-hand names for kernel per-process open file flags from this table:

#     ALLC	 allocated
#     BR	 the file has been read
#     BHUP	 activity stopped by SIGHUP
#     BW	 the file has been written
#     CLSG	 closing
#     CX	 close-on-exec (see fcntl(F_SETFD))
#     LCK	 lock was applied
#     MP	 memory-mapped
#     OPIP	 open pending - in progress
#     RSVW	 reserved wait
#     SHMT	 UF_FSHMAT set (AIX)
#     USE	 in use (multi-threaded)

#     NODE-ID	  (or INODE-ADDR for some dialects) contains a unique identifier for the file node (usually the kernel
#       vnode or inode address, but	also  occasionally  a concatenation of device and node number) when n has been specified to +f;

#     DEVICE	  contains  the device numbers, separated by commas, for a character special, block special, regular, directory or NFS file;
#     or ``memory'' for a memory file system node under Tru64 UNIX;
#     or the address of the private data area of a Solaris socket stream;
#     or a kernel reference address that identifies the file (The  kernel  reference address may be used for FIFO's, for example.);
#     or the base address or device name of a Linux AX.25 socket device.
#     Usually  only	 the lower thirty two bits of Tru64 UNIX kernel addresses are displayed.

#     SIZE, SIZE/OFF, or OFFSET is the size of the file or the file offset in bytes.	A value is  displayed in  this  column
#       only  if it is available. Lsof displays whatever value size or offset is appropriate for the type of the file and the version of lsof.

#     In other cases, files don't have true sizes - e.g., sockets, FIFOs, pipes - so lsof displays for their sizes  the
#     content  amounts  it finds in their kernel buffer descriptors (e.g., socket buffer size counts or TCP/IP window sizes.)

#     The  file size is displayed in decimal; the offset is normally displayed in decimal with a leading ``0t'' if it contains 8
#     digits or less; in hexadecimal with a leading ``0x'' if it is longer than 8 digits.  (Consult the -o o option description
#     for information on when 8 might default  to  some	other value.)

#     Thus	the  leading ``0t'' and ``0x'' identify an offset when the column may contain both a size and an offset (i.e., its title is SIZE/OFF).

#     If the -o option is specified, lsof always displays  the  file  offset  (or nothing  if no offset is available)
#       and labels the column OFFSET.  The offset always begins with ``0t'' or ``0x'' as described above.
#       The lsof user can control the switch from ``0t'' to ``0x'' with  the	-o  o option.

#     If the -s option is specified, lsof always displays the file size (or nothing if no size is available) and labels the column SIZE.
#       The -o and -s options are mutually exclusive; they can't both be specified.
#       For  files  that don't have a fixed size - e.g., don't reside on a disk device - lsof will display appropriate information
#       about the current size  or position  of	the file if it is available in the kernel structures that define the file.

#           NLINK	  contains the file link count when +L has been specified;
#           NODE	  is the node number of a local file;
#             or the inode number of an NFS file in the server host;
#             or the Internet protocol type - e.g, ``TCP'';
#             or ``STR'' for a stream;
#             or ``CCITT'' for an HP-UX x.25 socket;
#             or the IRQ or inode number of a Linux AX.25 socket device.
#           NAME	  is the name of the mount point and file system on which the file resides;
#             or the name of a file specified in the names	option	(after	any  symbolic links have been resolved);
#             or the name of a character special or block special device;
#             or  the  local  and  remote Internet addresses of a network file;
#                 the local host name or IP number is followed by a colon (':'), the port, ``->'',  and the  two-part	remote address;
#                 IP addresses may be reported as numbers or names, depending on the +|-M, -n, and -P options;
#                 colon-separated IPv6 num bers	 are   enclosed	  in   square  brackets;  IPv4	INADDR_ANY and IPv6 IN6_IS_ADDR_UNSPECIFIED
#                 addresses, and zero port numbers are represented by an  asterisk ('*');
#                 a UDP destination address may be followed by the amount of time elapsed since the last packet was sent to the destination;
#                 TCP, UDP and  UDPLITE	remote	addresses  may	be followed by TCP/TPI information in parentheses
#                 state (e.g., ``(ESTABLISHED)'', ``(Unbound)''), queue  sizes, and  window  sizes  (not  all dialects)
#                 in a fashion similar to what net‐ stat(1) reports; see the -T option description or the	 description of the TCP/TPI
#                 field in OUTPUT FOR OTHER PROGRAMS for more information on state, queue size, and window size;
#             or the address or name of a UNIX domain socket, possibly including a stream clone device name, a file system object's path name,
#                local and foreign kernel addresses, socket pair information, and a bound vnode address;
#             or the local and remote mount point names of an NFS file;
#             or ``STR'', followed by the stream name;
#             or a stream character device name, followed by ``->'' and the	 stream	 name
#             or a list of stream module names, separated by ``->'';
#             or  ``STR:'' followed by the SCO OpenServer stream device and module names, separated by ``->'';

#           or system directory name, `` -- '', and as many components of the path name as  lsof can find in the kernel's name cache for selected dialects

#           or ``PIPE->'', followed by a Solaris kernel pipe destination address;

#           or ``COMMON:'', followed by the vnode device information structure's device
#           name, for a Solaris common vnode;

#           or  the  address  family,  followed  by a slash (`/'), followed by fourteen
#           comma-separated bytes of a non-Internet raw socket address;

#           or the HP-UX x.25 local address, followed by the virtual connection  number
#           (if any), followed by the remote address (if any);

#           or ``(dead)'' for disassociated Tru64 UNIX files - typically terminal files
#           that have been flagged with the TIOCNOTTY ioctl and closed by daemons;

#           or ``rd=<offset>'' and ``wr=<offset>'' for the values of the read and write
#           offsets of a FIFO;

#           or  ``clone n:/dev/event'' for SCO OpenServer file clones of the /dev/event
#           device, where n is the minor device number of the file;

#           or ``(socketpair: n)'' for a Solaris 2.6, 8, 9  or 10 UNIX  domain  socket,
#           created by the socketpair(3N) network function;

#           or ``no PCB'' for socket files that do not have a protocol block associated
#           with them, optionally followed by ``,	 CANTSENDMORE''	 if  sending  on  the
#           socket  has  been disabled, or ``, CANTRCVMORE'' if receiving on the socket
#           has been disabled (e.g., by the shutdown(2) function);

#           or the local and remote addresses of a Linux IPX socket file	in  the	 form
#           <net>:[<node>:]<port>,  followed in parentheses by the transmit and receive
#           queue sizes, and the connection state;

#           or ``dgram'' or ``stream'' for the type UnixWare 7.1.1 and above  in-kernel
#           UNIX domain sockets, followed by a colon (':') and the local path name when
#           available, followed by ``->'' and the remote path name or kernel socket ad‐
#           dress in hexadecimal when available;

#           or the association value, association index, endpoint value, local address,
#           local port, remote address and remote port for Linux SCTP sockets;

#           or ``protocol: '' followed by the Linux socket's protocol attribute.


# lsof -FacCdDfFgGiKklLmMnNopPrRsStTuzZ
# lsof your_dir | awk '{for(i=9;i<=NF;++i)print $i}'
#  lsof -pcf
#    These are the fields that lsof will produce.  The single character listed first is the field identifier.
#    When the field selection character list is empty, all standard fields are selected
#    (except the raw device field, security context and zone field for compatibility reasons) and the NL field terminator is used.
#      a    file access mode
#      c    process command name (all characters from proc or user structure)
#      C    file structure share count
#      d    file's device character code
#      D    file's major/minor device number (0x<hexadecimal>)
#      f    file descriptor (always selected)
#      F    file structure address (0x<hexadecimal>)
#      G    file flaGs (0x<hexadecimal>; names if +fg follows)
#      g    process group ID
#      i    file's inode number
#      K    tasK ID
#      k    link count
#      l    file's lock status
#      L    process login name
#      m    marker between repeated output
#      M    the task comMand name
#      n    file name, comment, Internet address
#      N    node identifier (ox<hexadecimal>
#      o    file's offset (decimal)
#      p    process ID (always selected)
#      P    protocol name
#      r    raw device number (0x<hexadecimal>)
#      R    parent process ID
#      s    file's size (decimal)
#      S    file's stream identification
#      t    file's type
#      T    TCP/TPI information, identified by prefixes (the
#      `=' is part of the prefix):
#      QR=<read queue size>
#      QS=<send queue size>
#      SO=<socket options and values> (not all dialects)
#      SS=<socket states> (not all dialects)
#      ST=<connection state>
#      TF=<TCP flags and values> (not all dialects)
#      WR=<window read size>  (not all dialects)
#      WW=<window write size>  (not all dialects)
#      (TCP/TPI information isn't reported for all supported
#      UNIX dialects. The -h or -? help output for the -T option will show what TCP/TPI reporting can be requested.)
#      u    process user ID
#      z    Solaris 10 and higher zone name
#      Z    SELinux security context (inhibited when SELinux is disabled)
#      0    use NUL field terminator character in place of NL
#      1-9  dialect-specific field identifiers (The output of -F? identifies the information to be found in dialect-specific fields.)


# Normally  lsof  ends each field with a NL (012) character.  The 0 (zero) field identifier character may be specified to change the field terminator character
# to a NUL (000).  A NUL terminator may be easier to process with xargs (1), for example, or with programs whose quoting mechanisms may not easily
# cope with the range of characters  in  the  field  output. When the NUL field terminator is in use, lsof ends each process and file set with a NL (012).
