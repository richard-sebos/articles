- What is the goal:
-highligh CUPS printing feature (that sucks)
- get a better job in IT
  
- There have been projects in my past where  as Jack Bergman  said "There's never enough time to do it right, but there's always enough time to do it over"
- For me, those are project that there was a additional requertment that took the project from what the customer want to what the customer needed.
- I felt vindatacated when after the project was delievred one of the users would say, to bad it did this, which is what I wanted to add.
- CUPS has taken the time to take of the additional feature and it make setting up complex print stituation easier.

## CUPS Classes
- If you have critical business process that  count on printing some day the printer will either jam, break or just not be fast enough to scale with the change in the business
- CUPS has classes to help with this
- CUPS classes are a way to group printer into a print queue so they can be used to print.

## Round Robin Printing
- It's funny and not the good kind, that on know our Zerba printers at work print a label in 0.7 seconds.
- Why do I know this, because if some prints 150 labels and the users feels it's printing to slow I can say, but it should take around 2 minutes aleast just for the printer to print those
- That same job spread across 5 printers would take 21 seconds
> Note: That is assuming every print job is just one label
- Setting up a printer class is easy by first defining the printers:
```bash
## create printers
sudo lpadmin -p vprinter1a -E -v ipp://192.168.35.131:631/printers/fileprint -P /etc/cups/ppd/vprinter1a.ppd
sudo lpadmin -p vprinter1b -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.ppd
sudo lpadmin -p vprinter1c -E -v ipp://192.168.35.133:631/printers/fileprint -P /etc/cups/ppd/vprinter1c.ppd
sudo lpadmin -p vprinter1d -E -v ipp://192.168.35.134:631/printers/fileprint -P /etc/cups/ppd/vprinter1d.ppd
sudo lpadmin -p vprinter1e -E -v ipp://192.168.35.135:631/printers/fileprint -P /etc/cups/ppd/vprinter1e.ppd
```

- then defining the class

```bash
## Define class
sudo lpadmin -p vprinter1a -c rr_labels
sudo lpadmin -p vprinter1b -c rr_labels
sudo lpadmin -p vprinter1c -c rr_labels
sudo lpadmin -p vprinter1d -c rr_labels
sudo lpadmin -p vprinter1e -c rr_labels
```
- The the application prints, it prints to `rr_labels` and CUPS handles the rest.
- For one small setup effort, and the cost of printers you can have this setup in no time.

## Failover Printing
- Just as important as speeding up printing, there is what to do when printer fail.
- More than once, I've received a call about a printer down and they want to user the printer beside it.
- Assuming the printers didn't already exists:
```bash
## Primary Printer
sudo lpadmin -p vprinter1a -E -v ipp://192.168.35.131:631/printers/fileprint -P /etc/cups/ppd/vprinter1a.ppd

## Seconard printer, with it's own print queue
sudo lpadmin -p vprinter1b -E -v ipp://192.168.35.132:631/printers/fileprint -P /etc/cups/ppd/vprinter1b.pp
```
- now 
