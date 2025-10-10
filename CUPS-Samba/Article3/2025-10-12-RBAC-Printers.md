
## Securing Printers with CUPS: Why It Matters

As a Linux administrator, you often find yourself tackling some surprising tasks—and printer management is definitely one of them. For me, it all started with three CUPS servers managing over 50 printers. Thankfully, CUPS was relatively easy to work with at a high level. But as the infrastructure grew from 3 to 7 servers and over a hundred printers spread across the country, I started wondering: should a user on the East Coast really be able to see and print to a West Coast printer?

That simple question led me down a path of exploring how CUPS handles access control, and more importantly, how it can be secured at the **printer level**.

---

## Why You Should Care

CUPS (Common UNIX Printing System) is deceptively straightforward. It offers a lot of flexibility and user-friendliness—great traits until you realize that same ease of use can lead to potential security issues. Sure, it's handy when users can check the status of their print jobs or see printer queues. But what if they can pause a printer, cancel someone else’s jobs, or worse—delete the printer entirely?

Now imagine a malicious actor gaining access. Without proper controls, they could cause real damage—deleting jobs, changing printer configurations, or accessing sensitive documents. Thankfully, CUPS offers built-in role-based access control (RBAC) features that allow you to manage who can print, where print jobs can come from, and who can see or modify printers—all at the **individual printer level**.

---

## Understanding Printer-Level RBAC in CUPS

### Controlling Where Print Jobs Can Come From

Today, you might have specialized printers—like those printing shipping labels or receipts—connected to your network. Ideally, these printers are on isolated subnets behind strict firewall rules. But even so, CUPS gives you fine-grained control over who can send print jobs.

You can define restrictions in `cupsd.conf` that allow only specific IP addresses to send jobs to a particular printer. For example, a shipping label printer may only need to accept jobs from the remote order processing system and the local host:

```conf
## Restrictions for Shipping Label Printer
## Inside of cupsd.conf
<Location /printers/SH_LABEL_IL_01>
  AuthType Basic
  Require ip 10.10.1.10         # Order system
  Require ip 127.0.0.1          # Localhost
</Location>
```

This ensures that only authorized systems can send print jobs to that printer, reducing the attack surface significantly.

---

### Controlling Who Can Print

In a [previous article](https://richard-sebos.github.io/sebostechnology/posts/CUPS-RBAC/), I discussed how to restrict access to the CUPS web interface at a global level. However, CUPS also allows for similar restrictions **per printer**. This becomes especially useful for sensitive devices like check printers.

You can assign access to specific users or groups using the `Require user` or `Require group` directives in the printer configuration. For example, only members of the `ap_sup` (Accounts Payable Supervisors) group should be able to print checks:

```conf
<Printer AP_CHECKS>
  PrinterId 10
  Require group ap_sup
  ...
</Printer>
```

Not only does this limit who can send jobs.
### CUPS and Emails
- Special printing like check, highend printers or secure location, may want to track what has been printed.
-  CUPS provides a subscription option to receive and email when:
  - printer-stopped → printer paused/offline.
  - printer-state-changed → covers paused, resumed, etc.
  - printer-restarted → CUPS server restarted.
  - job-completed → job finished.
  - server-restarted → CUPS daemon restarted.

```bash
## example of email when printing
lp -d PRINTER_NAME \
   -o notify-recipient-uri=mailto:you@example.com \
   -o notify-events=job-completed

## or 
## Send email when any printer is paused or offline
lp -o notify-recipient-uri=mailto:you@example.com \
   -o notify-events=printer-stopped
```

- the latter one can be useful when a printer pauses because of network issues.
- It allows you to look into the logs shortly after the printer is having issues.
> Note: CUPS needs access to an SMTP server to be able send emails out.
  
### Policies and Printer

- CUPS Policies defined in the `cupsd.conf` are used to define what a user can see in CUPS web portal
- The Polices can be assigned to a printer giving granuality control over what a user can do
- So on a check printer, you would not want the option to reprint

```bash
## In the printer.conf
<Printer AP_CHECKS>
  PrinterId 10
  Require group ap_sup
  ...
 # Assignd  custom policy check-print
  OpPolicy check-print
</Printer>
```
```bash
## Sets custom policy
<Policy check-print>
  <Limit CUPS-Get-Document>
    AuthType Default
    Order deny,allow
    Deny from all
  </Limit>
</Policy
```

## Do you Need to Do This
- CUPS will install and work without these options and these options do not make the service run CUPS any more secure
- These are about securing the business process (restircted user in check printing), ensure critical resources are only used for what is needed (spefic IP a label printer) and getting a had of issues (emails when printers are down)

 Side note, CUPS like Putty was released in 1999.  
 - Back in 1999, the average CPU where single core process running 300-600MHz.
 - Now my home server has two socker each with 12 cores and running at 2.5Ghz but CUPS is the same plain looking print server about to hand a couple of print job here an there and I have server that can 500,000 jobs a month.
 - I've being in IT just a little longer than them but I can't remember a time when I was working professional and not having them around.
