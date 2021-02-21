# CBLiteViewer
I originally created this project to allow adding a whole bunch of records to an existing Couchbase Lite DB to do some load testing, and to test the search capability, etc. on an IPhone application I wrote.  This program should work with Couchbase Lite version 2.X.  How I used this program was to launch the IPhone app I wrote in the simulator, create 1 entry, exited the application, copied the DB to another location and opened it with this program.  I added a whole bunch of new entries and copied it back to the original location.  I thought this would be faster than using the appication itself since I could copy the tables and make a few changes.  This program should allow you to do the following:
Open an existing Couchbase Lite Database and view the contents
copy/paste a table
delete a table
Add dictionary entry
Add an array of intrinsic items as a value (string, number).  Note an array of strings are denoted by [], e.g. items : [ item1, item2, item3]
Delete entry
Change a value
Change a key
Copy/paste an (dictionary) array item
Delete an array item
Save a new table to the database
Save a table change to the database
Add a picture as a value
View a picture
Add new table
Render timestamp into a date
Add date as a value
Modify value array fields (bodies of water)
Copy/paste dictionary item
TODO: Add dictionary array item
TODO: finish the creating a new database thread
