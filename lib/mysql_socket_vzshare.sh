#!/bin/sh

# Created by Tauren Mills (tauren at tauren dot com) 2007-11-15

###################################
# Start of Configuration settings #
###################################

# Location of private containers:
PRIVATE=/vz/private

# Starting CT ID.  CTIDs with this ID or greater will have mysql.sock link created
START_CTID=1001

# Stopping CT ID.  CTIDs with this ID or less will have mysql.sock link created
STOP_CTID=2000

# Shared Mysql CT ID:
MYSQL_CTID=201

# Location of mysql socket file
MYSQL_SOCK_DIR=/var/lib/mysql

# Mysql socket file name
MYSQL_SOCK=mysql.sock

#################################
# End of Configuration settings #
#################################

# Display output if quiet is 0
QUIET=0

if [ $# -eq 1 -a "$1" = "--quiet" ]; then
        QUIET=1
fi

# Full path to socket
MYSQL_SOCK_FILE=${PRIVATE}/${MYSQL_CTID}${MYSQL_SOCK_DIR}/${MYSQL_SOCK}

[ $QUIET -eq 0 ] && echo
[ $QUIET -eq 0 ] && echo "Relinking process starting..."

# Get current location so we can set it back later
oldDirectory=`pwd`

# Check to see if MySQL container socket exists
if [ -S "${MYSQL_SOCK_FILE}" ]; then

        # Get inode of MySQL container socket
        mysql_inode=`ls -i ${MYSQL_SOCK_FILE} | awk '{ print $1;}'`

        # Search through containers
        cd $PRIVATE
        for i in * ; do
                # The current container to process
                veid=$i

                # Check if container should be processed
                if [ $veid -ne $MYSQL_CTID -a $veid -ge $START_CTID -a $veid -le $STOP_CTID ]; then

                        # Get this container's socket
                        vesock=${PRIVATE}/${veid}${MYSQL_SOCK_DIR}/${MYSQL_SOCK}

                        # Make sure folder exists
                        mkdir -p ${PRIVATE}/${veid}${MYSQL_SOCK_DIR}

                        # Check to see if this container has a socket already
                        if [ -S "${vesock}" ]; then
                                # Get inode of this container socket
                                ve_inode=`ls -i ${vesock} | awk '{ print $1;}'`

                                # Test if sockets are the same
                                if [ $mysql_inode -eq $ve_inode ]; then
                                        # No action required
                                        [ $QUIET -eq 0 ] && echo "$veid VALID:  socket ${vesock}"
                                else
                                        # Remove existing file if any
                                        if [ -a "${vesock}" ]; then
                                                rm ${vesock}
                                        fi

                                        # Create hardlink to mysql socket file
                                        ln ${MYSQL_SOCK_FILE} ${vesock}

                                        [ $QUIET -eq 0 ] && echo "$veid FIXED:  socket ${vesock}"
                                fi
                        else
                                # Socket didn't exist or file wasn't a socket

                                # Remove existing file if any
                                if [ -a "${vesock}" ]; then
                                        rm ${vesock}
                                fi

                                # Create hardlink to mysql socket file
                                ln ${MYSQL_SOCK_FILE} ${vesock}

                                [ $QUIET -eq 0 ] && echo "$veid FIXED:  socket ${vesock}"
                        fi
                else
                        [ $QUIET -eq 0 ] && echo "$veid SKIPPED"
                fi
        done
else
        [ $QUIET -eq 0 ] && echo "${MYSQL_SOCK_FILE} does not exist. Is MySQL running?"
fi

cd $oldDirectory

[ $QUIET -eq 0 ] && echo "Relinking process complete."
[ $QUIET -eq 0 ] && echo