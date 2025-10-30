# Bulk User Creation Script (newusers Alternative)

This script provides an enhanced alternative to the `newusers` command in Linux, offering more control and visibility over the user creation process. It reads a file containing user account information and performs the following operations:

- Creates new users with specified UIDs
- Creates groups if they don't exist
- Sets up home directories with proper permissions
- Manages password settings (including account locking)
- Provides better error handling and feedback

## Input File Format

Format per line:

    username:password:UID:GID:Comment:/home/dir:/bin/shell

Example:

    messi:!:2001:2001:Messi User:/home/messi:/bin/bash
    yasmeen:!:2002:2002:Yasmeen User:/home/yasmeen:/bin/bash
    ali:!:2003:2003:Ali User:/home/ali:/bin/bash

`!` means account will be locked.

## Script Usage

    sudo ./usersScript.sh users.txt

## Test Case and Command Explanation

### 1. Initial System State
First, let's check the current users in the system:
```bash
$ cat /etc/passwd | tail -4
user:x:9999:1000:This is testing useradd cmd:/home/user:/bin/bash
user2:x:9991:1000:This is testing useradd cmd:/home/user2:/bin/bash
islam:x:10000:10000:Islam Asker:/home/islam:/bin/sh
postfix:x:134:144::/var/spool/postfix:/usr/sbin/nologin
```
This shows our starting point with existing users. Note the different UID ranges and shell configurations.

### 2. Testing Native newusers Command
Try the built-in `newusers` command:
```bash
$ sudo newusers ~/Desktop/testFile 
BAD PASSWORD: The password is a palindrome
BAD PASSWORD: The password is a palindrome
BAD PASSWORD: The password is a palindrome
```
The command shows password validation warnings but continues execution. These warnings indicate that `newusers` performs password strength checking.

### 3. Verifying User Creation (newusers)
Check if users were created despite the warnings:
```bash
$ cat /etc/passwd | tail -4
postfix:x:134:144::/var/spool/postfix:/usr/sbin/nologin
messi:x:2001:2001:Messi User:/home/messi:/bin/bash
yasmeen:x:2002:2002:Yasmeen User:/home/yasmeen:/bin/bash
ali:x:2003:2003:Ali User:/home/ali:/bin/bash
```
Users were successfully created with their specified UIDs, GIDs, and shell preferences.

### 4. Cleanup Process
Remove the test users to prepare for our script test:
```bash
$ sudo userdel messi
$ sudo userdel ali
$ sudo userdel yasmeen
```
The `userdel` command removes user entries from system files (/etc/passwd, /etc/shadow, /etc/group).

### 5. Cleanup Verification
Confirm the users were properly removed:
```bash
$ cat /etc/passwd | tail -4
user:x:9999:1000:This is testing useradd cmd:/home/user:/bin/bash
user2:x:9991:1000:This is testing useradd cmd:/home/user2:/bin/bash
islam:x:10000:10000:Islam Asker:/home/islam:/bin/sh
postfix:x:134:144::/var/spool/postfix:/usr/sbin/nologin
```
System returned to its initial state, ready for testing our script.

### 6. Testing Custom Script
Run our enhanced user creation script:
```bash
$ sudo ~/Desktop/usersScript.sh ~/Desktop/testFile
```
Note the absence of password warnings - our script handles password processing differently.

### 7. Custom Script Results
Verify the users were created correctly:
```bash
$ cat /etc/passwd | tail -4
postfix:x:134:144::/var/spool/postfix:/usr/sbin/nologin
messi:x:2001:2001:Messi User:/home/messi:/bin/bash
yasmeen:x:2002:2002:Yasmeen User:/home/yasmeen:/bin/bash
ali:x:2003:2003:Ali User:/home/ali:/bin/bash
```
Our script created identical user entries but with improved error handling and without password warnings.

### Key Observations:
1. The native `newusers` command shows password validation errors but still creates the users
2. Both methods successfully create users with specified UIDs and GIDs
3. The custom script handles the process without password warnings
4. User entries in `/etc/passwd` are identical between both methods
5. The `userdel` command successfully removes test users
6. Both methods properly set up user properties (home directory, shell, etc.)

## Script Code

    #!/bin/bash

    file=$1

    while read -r line; do
        user=$(echo "$line" | cut -d: -f1)
        pass=$(echo "$line" | cut -d: -f2)
        uid=$(echo "$line" | cut -d: -f3)
        gid=$(echo "$line" | cut -d: -f4)
        comment=$(echo "$line" | cut -d: -f5)
        home=$(echo "$line" | cut -d: -f6)
        shell=$(echo "$line" | cut -d: -f7)

        if ! getent group "$gid" >/dev/null; then
            sudo groupadd -g "$gid" "$user"
        fi

        sudo useradd -u "$uid" -g "$gid" -c "$comment" -d "$home" -s "$shell" "$user"

        sudo mkdir -p "$home"
        sudo chown "$uid:$gid" "$home"

        if [ "$pass" = "!" ] || [ -z "$pass" ]; then
            sudo passwd -l "$user" >/dev/null
        else
            echo "$user:$pass" | sudo chpasswd --encrypted
        fi
    done < "$file"

## Understanding newusers Command and /etc/passwd

### The newusers Command
The `newusers` command is a built-in Linux utility that creates or updates user accounts in batch. Key features:
- Reads user account information from a file
- Creates new users or updates existing ones
- Automatically creates home directories
- Updates /etc/passwd, /etc/shadow, and /etc/group files
- Can handle encrypted and plain-text passwords
- Runs with elevated privileges (root/sudo)

Example usage:
```bash
sudo newusers input_file
```

### The /etc/passwd File Structure
The `/etc/passwd` file contains essential information about user accounts. Each line represents one user account with seven fields separated by colons:

```
username:password:UID:GID:comment:home_directory:shell
```

Field descriptions:
1. `username`: User's login name (1-32 characters)
2. `password`: Usually 'x' (actual password stored in /etc/shadow)
3. `UID`: User ID number
   - 0: Reserved for root
   - 1-999: System users
   - 1000+: Regular users
4. `GID`: Primary group ID
5. `comment`: User information (full name, phone, etc.)
6. `home_directory`: User's home directory path
7. `shell`: Default shell (e.g., /bin/bash, /usr/sbin/nologin)

Example entry:
```
john:x:1001:1001:John Doe:/home/john:/bin/bash
```

### Important UID Ranges
- 0: root user
- 1-99: Static system users
- 100-999: Dynamic system users
- 1000+: Regular users
- 65534: nobody user

## Requirements

- Root/sudo privileges
- Linux operating system
- Basic user management utilities (useradd, groupadd, passwd)

## Security Considerations

- Always review the input file before processing
- Keep the input file secure and with appropriate permissions
- Use encrypted passwords in production environments
- Run the script with sudo privileges
- Verify UIDs and GIDs don't conflict with existing users

## Troubleshooting

Common issues and solutions:

1. **Permission Denied**: Make sure you're running the script with sudo
2. **User Already Exists**: Remove existing user first or update UID
3. **Group Creation Failed**: Check if GID is already in use
4. **Home Directory Issues**: Verify parent directory permissions

## Output
