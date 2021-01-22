# MongoDB-ReplicaSet-Auth-Docker-Compose

A Docker Compose example for a MongoDB replica set with auth enabled.

## Purpose

Sometimes it is necessary to connect your application in a dev environment
with a production like MongoDB to confirm that some of your application changes
will work in production as well. This is often not as easy as we would hope
since most dev environment MongoDB instances probably run as a single instance
without any auth enabled and we have to spin up our own instances locally for
testing a production like setup. This repository aims to provide some example
code that can easily be used to run MongoDB locally in a replica set and with
auth enabled.

**Warning: The supplied keyfile should only be used when running MongoDB
locally, generate your own keyfile otherwise!**

## Initial MongoDB Setup

The following explains the few manual steps that are needed to run three
instances of MongoDB in a replica set, to have auth enabled and to create a few
users for both the administration of the DB and for your application.

We start out at the root of the repository in a terminal window. The following
command starts all three instances of MongoDB:

```shell
docker-compose up -d
```

Once all three instances are up and running, you can use the following commands
to open a mongo shell and to initiate the replica set:

```shell
docker exec -it db01 /bin/bash
# now we are inside the db01 container
mongo --port 30001
# now we are inside the MongoDB shell
rs.initiate({
  "_id": "rs0",
  "version": 1,
  "members" : [
    {"_id": 1, "host": "db01:30001"},
    {"_id": 2, "host": "db02:30002"},
    {"_id": 3, "host": "db03:30003"}
  ]
})

# you can get the replica set status with
rs.status()

# once one of the replica set members has been elected to the Primary we can
# move on
```

From now on we are only able to create the users on the primary instance. You
should know which instance is the primary from running `rs.status()` earlier.
If it happens to be another instance than the one running on `db01`, exit out
of `db01` and `docker exec` into the Docker container that is running the
primary MongoDB instance.

Now we can create our admin user. Even though all three MongoDB instances are
running in auth mode, we were able to connect to them with the MongoDB shell
without any auth because there was no admin user just yet.

Let's create our admin user:
```shell
# we are again inside the MongoDB shell connected per MongoDB shell to the
# primary replica set member.
use admin
db.createUser(
  {
    user: "myUserAdmin",
    pwd: "abc123",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, { role: "clusterAdmin", db: "admin" } ]
  }
)
```

Now that we created our first admin user we have to exit the MongoDB shell and
start it again but this time we connect as the newly created admin user. We
start off from inside the db01 container as before but this time we use the
following command to start the MongoDB shell. This time we pass a user, a
password and the database we want to authenticate against:

```shell
mongo --port 30001 -u "myUserAdmin" -p "abc123" --authenticationDatabase "admin"
```

All that is left to do is to create users for all the databases your application
is using. In this example we have a database called `mydb`. You simply have to
repeat the two below commands for each of your databases where you replace
`mydb` with your actual database name.

```shell
use mydb
db.createUser(
  {
    user: "myTester",
    pwd: "xyz123",
    roles: [ { role: "readWrite", db: "mydb" }]
  }
)
```

That's it, now you have three MongoDB instances running as a replica set and
requiring auth to connect to it.
