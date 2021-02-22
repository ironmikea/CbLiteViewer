# CBLiteViewer
![CbLiteViewer](https://user-images.githubusercontent.com/5051692/108670730-5fc76780-74ad-11eb-8bf0-b7ac253bd91a.png)

I originally created this project to allow adding a whole bunch of records to an existing Couchbase Lite DB to do some load testing, and to test the search capability, etc. on an IPhone application I wrote.  This program should work with Couchbase Lite version 2.X.  How I used this program was to launch the IPhone app I wrote in the simulator, create 1 entry, exited the application, copied the DB to another location and opened it with this program.  I added a whole bunch of new entries and copied it back to the original location.  I thought this would be faster than using the appication itself since I could copy the tables and make a few changes.
