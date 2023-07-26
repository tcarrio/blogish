+++
title = "Recovering Access to Synology DSM"
slug = "synology-dsm-access-recovery"
+++

I'll paint the landscape. Suppose you happened to have just applied some new permissions in your system an the effort to minimize permissions and otherwise improve the security footprint of your Synology NAS. You fly through rules on AFS, NFS, rsync, DSM, FTP- knocking off these services that you don't use (or don't think you do). Now your system has every user blocked from DSM by default. So what was DSM again?

Oh, right. It's the web UI for your Synology NAS. You're locked out and can't administrate your server anymore. What do you do? Well, there are a couple of options depending on what access you have left. The worst case scenario is 

## Update your DSM permissions

If you still have SSH permissions and sudo privileges on the user, you can take this approach.

First, connect to your Synology NAS via SSH:

```bash
ssh username@synology_hostname
```

Next, get the user ID of your user by username:

```bash
id username

# uid=1026(username) gid=100(users) groups=100(users),101(administrators)
```

You'll have to take note of the ID (in the command output as `uid=$id($username)`, e.g. 1026).

The next step is modifying the SQLite database. Synology maintains its application-level privileges in a SQLite database at `/etc/synoappprvilege.db`. You can modify this in order to provide yourself permissions. Just to be safe, make a copy of the database. In case you decide to truncate a table.

```bash
# copies the file to the same name with a `.bak` extension
sudo cp /etc/synoappprivilege.db{,.bak}
```

Now open the database using

```bash
sudo sqlite3 /etc/synoappprivilege.db
# SQLite version 3.40.0 2022-11-16 12:10:08
# Enter ".help" for usage hints.
# sqlite>
```

The table we'll need to update is `AppPrivRule`. I prefer to double-check all commands before I run them, especially for things like modifying a database. The SQL `INSERT` query itself relies on the structure of your `VALUES` matching that of the table schema. You can output the table schema in SQLite by calling:

```sql
PRAGMA table_info(AppPrivRule);

-- 0|Type|INTEGER|0||0
-- 1|ID|INTEGER|0||0
-- 2|App|varchar(50)|0||0
-- 3|AllowIP|TEXT|0||0
-- 4|AllowIPStd|TEXT|0||0
-- 5|DenyIP|TEXT|0||0
-- 6|DenyIPStd|TEXT|0||0
```

So the syntax in this case for inserting into the table will be `INSERT INTO AppPrivRule VALUES (Type: INTEGER, ID: INTEGER, App: VARCHAR(50), AllowIP: TEXT, AllowIPStd: TEXT, DenyIP: TEXT, DenyIPStd: TEXT);`

The permission to access DSM (at the time of writing) was `'SYNO.Desktop'`.

As such, you'd run the following query (to allow all IPs, block none, for the $id from earlier):

```sql
INSERT INTO AppPrivRule
VALUES (
  0,                                         -- Type
  1026,                                      -- ID
  'SYNO.Desktop',                            -- App
  '0.0.0.0',                                 -- AllowIP
  '0000:0000:0000:0000:0000:FFFF:0000:0000', -- AllowIPStd
  '',                                        -- DenyIP
  ''                                         -- DenyIPStd
);
```

At this point you should be able to go through your usual login flow into the DSM web UI.

## Reset your NAS (a destructive action)

Synology already provides a guide on this which you can find [here][synology-reset-doc].


<!-- References -->
[synology-reset-doc]: https://kb.synology.com/en-us/DSM/tutorial/How_do_I_log_in_if_I_forgot_the_admin_password