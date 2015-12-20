#!/bin/bash
#Script to mount to network and automate backup using rsync.
# Specify the mount point here.
#Automount can be done by adding following lines of code into 
sudo mount -t cifs -o user=klamichh,domain=nexus,sec=ntlmssp,file_mode=0777,dir_mode=0777 //ecresearch.uwaterloo.ca/klamichh ~kamal/ecresearch
#Give the correct password (WATIAM user password)
mount_point='/home/kamal/ecresearch'

echo "#####"
echo ""
# Check whether target volume is mounted, and mount it if not.
if ! mountpoint -q ${mount_point}/; then
	echo "Mounting the folder ecresearch."
	echo "Mountpoint is ${mount_point}"
	if ! mount ${mount_point}; then
		echo "An error code was returned by mount command!"
		exit 5
	else echo "Mounted successfully.";
	fi
else echo "${mount_point} is already mounted.";
fi
# Target volume **must** be mounted by this point.
if ! mountpoint -q ${mount_point}/; then
	echo "Mounting failed!!!!!!!!!!!!!! No backup volume"
	exit 1
fi

echo "Preparing to transfer differences using rsync."

# Use the year or month to create a new backup directory each year/month. Let's use year here.
current_year=`date +%Y`
#construct back-up path
backup_path=${mount_point}'/rsync-backup/'${current_year}

echo "Backup storage directory path is ${backup_path}"

echo "Starting backup of /home/kamal/work . . . "
# Create the target directory path if it does not already exist.
mkdir --parents ${backup_path}/
# Note that the 2>&1 part simply instructs errors to be sent to standard output
sudo rsync --archive --hard-links \ 
--verbose --human-readable --itemize-changes --progress \
--delete --delete-excluded --exclude='/.Trash-1000/' \
 ~kamal/work/ ${backup_path}/ 2>&1 | tee ~kamal/work/rsync-output.txt

echo "Starting backup of /home/work ......... "
mkdir --parents ${backup_path}/
# This time use the -a flag with the tee command, so that it appends to the end
# of the rsync-output.txt file rather than start a new file from scratch.
sudo rsync --archive --verbose --human-readable --itemize-changes --progress \
--delete --delete-excluded \
--exclude='/.Trash-1000/' \
~kamal/work/ ${backup_path}/ 2>&1 | tee -a ~kamal/work/rsync-output.txt
# Ask if target should be unmounted.
echo -n "Do you want to unmount ${mount_point} Enter any key except y/yes."
read -p ": " unmount_answer
unmount_answer=${unmount_answer,,}  # make lowercase
if [ "$unmount_answer" == "y" ] || [ "$unmount_answer" == "yes" ]; then
	if ! umount ${mount_point}; then
		echo "An error code was returned by umount command!"
		exit 5
	else echo "UNMOUNTED successfully.";
	fi
else echo "Volume remains mounted.";
fi
echo ""
echo "####"
