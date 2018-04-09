# Requirements
1) SQL Server Tested on 10.1.31-MariaDB MariaDB Server
2) NPM
3) NodeJS
4) Package Manager such as PM2 (optional)

# Set UP
1) Run db.sql on your database server to set up the required tables
2) create a .env file in this directory and fill in the required information (see .envSample)
3) run `npm install` to install the required dependencies

# Running the script
1) Run the script with `npm start` if database was set up successfully it should run and begin populating the db
2) Run the script within PM2 (Optional)
