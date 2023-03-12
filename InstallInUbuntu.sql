To install PostgreSQL, first refresh your server’s local package index:

sudo apt update
Then, install the Postgres package along with a -contrib package that adds some additional utilities and functionality:

sudo apt install postgresql postgresql-contrib
Ensure that the service is started:

sudo systemctl start postgresql.service
Step 2 — Using PostgreSQL Roles and Databases
By default, Postgres uses a concept called “roles” to handle authentication and authorization. These are, in some ways, similar to regular Unix-style users and groups.

Upon installation, Postgres is set up to use ident authentication, meaning that it associates Postgres roles with a matching Unix/Linux system account. If a role exists within Postgres, a Unix/Linux username with the same name is able to sign in as that role.

The installation procedure created a user account called postgres that is associated with the default Postgres role. There are a few ways to utilize this account to access Postgres. One way is to switch over to the postgres account on your server by running the following command:

sudo -i -u postgres
Then you can access the Postgres prompt by running:

psql
This will log you into the PostgreSQL prompt, and from here you are free to interact with the database management system right away.

To exit out of the PostgreSQL prompt, run the following:

\q
This will bring you back to the postgres Linux command prompt. To return to your regular system user, run the exit command:

exit
Another way to connect to the Postgres prompt is to run the psql command as the postgres account directly with sudo:

sudo -u postgres psql
This will log you directly into Postgres without the intermediary bash shell in between.

Again, you can exit the interactive Postgres session by running the following:

\q
Step 3 — Creating a New Role
If you are logged in as the postgres account, you can create a new role by running the following command:

createuser --interactive
If, instead, you prefer to use sudo for each command without switching from your normal account, run:

sudo -u postgres createuser --interactive
Either way, the script will prompt you with some choices and, based on your responses, execute the correct Postgres commands to create a user to your specifications.

Output
Enter name of role to add: sammy
Shall the new role be a superuser? (y/n) y
Step 4 — Creating a New Database
Another assumption that the Postgres authentication system makes by default is that for any role used to log in, that role will have a database with the same name which it can access.

This means that if the user you created in the last section is called sammy, that role will attempt to connect to a database which is also called “sammy” by default. You can create the appropriate database with the createdb command.

If you are logged in as the postgres account, you would type something like the following:

createdb sammy
If, instead, you prefer to use sudo for each command without switching from your normal account, you would run:

sudo -u postgres createdb sammy
Step 5 — Opening a Postgres Prompt with the New Role
To log in with ident based authentication, you’ll need a Linux user with the same name as your Postgres role and database.

If you don’t have a matching Linux user available, you can create one with the adduser command. You will have to do this from your non-root account with sudo privileges (meaning, not logged in as the postgres user):

sudo adduser sammy
Once this new account is available, you can either switch over and connect to the database by running the following:

sudo -i -u sammy
psql
Or, you can do this inline:

sudo -u sammy psql
This command will log you in automatically, assuming that all of the components have been properly configured.

If you want your user to connect to a different database, you can do so by specifying the database like the following:

psql -d postgres
Once logged in, you can get check your current connection information by running:

\conninfo
Output
You are connected to database "sammy" as user "sammy" via socket in "/var/run/postgresql" at port "5432".
Conclusion
You are now set up with PostgreSQL on your Ubuntu 20.04 server. If you’d like to learn more about Postgres and how to use it, we encourage you to check out the following guides:
