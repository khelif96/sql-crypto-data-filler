To log in to mariaDB, you need to go through the mySQL command line interface

```sql
mysql -u root -p
/*then type in password which for this project was my emplid*/
```



Issue these commands to get your database to run your SQL file. 

```sql
USE db_name;
SOURCE backup-file.sql;
```


If you don't know what database you'd like to choose, issue the command:

```SQL
SHOW SCHEMAS;
```

which in this case has an output like this:

```SQL
+--------------------+
| Database           |
+--------------------+
| information_schema |
| local_crypto       |
| mysql              |
| performance_schema |
+--------------------+
```

I'm going to `USE local_crypto;` for this project. 
