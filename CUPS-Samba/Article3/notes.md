You’re thinking along the right lines. CUPS’ policy framework is flexible enough to let you map different IPP operations (like “Pause-Printer”, “CUPS-Delete-Printer”, etc.) to different user sets or groups. ([cups.org][1])

Here’s how you can approach implementing your role split using CUPS policies and `<Limit>` blocks.

---

## 1. Know the operations names you can control

CUPS supports many operations (IPP verbs) that you can reference in `<Limit>` blocks. Some relevant ones include:

* Printer-level operations: `Pause-Printer`, `Resume-Printer`, `Set-Printer-Attributes`, `Enable-Printer`, `Disable-Printer`, `Activate-Printer`, `Deactivate-Printer`, `CUPS-Reject-Jobs`, `CUPS-Accept-Jobs`, etc. ([cups.org][1])
* Job-level operations: `Send-Document`, `Send-URI`, `Print-Job`, `Print-URI`, `Cancel-Job`, `Hold-Job`, `Release-Job`, `Restart-Job`, `Purge-Jobs`, `Set-Job-Attributes`, `CUPS-Move-Job` etc. ([cups.org][1])
* Administrative operations: `CUPS-Add-Modify-Printer`, `CUPS-Delete-Printer`, `CUPS-Set-Default`, etc. ([cups.org][1])

You will need to group the operations you care about into `<Limit>` sections and assign them the proper “Require user …” rule.

---

## 2. Use groups (or users) in `Require user` or `Require group`

CUPS’ `Require` directive supports specifying **users** or **groups**. For example:

```conf
Require user alice bob
Require group cups_help_desk cups_admin
```

You’ll want to use `Require group ...` when you want to permit an entire role group (like `cups_help_desk`) to do something.

Also, `Order deny,allow` is typical (deny first, then allow for those matching).

---

## 3. An example policy based on your “role mapping” idea

Below is a sketch of how your `restricted-print` (or new policy) might look. You’ll have to adjust it to exactly the operations you want.

```conf
<Policy restricted-print>
  #
  # Job submission (printing) — who can send print jobs
  #
  <Limit Send-Document Send-URI Print-Job Print-URI>
    AuthType Default
    Require user @OWNER
    Require group cups_viewer cups_help_desk
    Order deny,allow
  </Limit>

  #
  # Printer maintenance / self-test / cleaning, etc.
  #
  <Limit CUPS-Get-Document Get-Printer-Attributes>  
    AuthType Default
    Require group cups_viewer cups_help_desk cups_admin
    Order deny,allow
  </Limit>

  #
  # Pause / Resume / Reject / Accept / Move / Cancel All / Modify Printer / Set Attributes / etc.
  #
  <Limit Pause-Printer Resume-Printer
         CUPS-Reject-Jobs CUPS-Accept-Jobs
         CUPS-Move-Job
         Cancel-Job # maybe more job operations
         Set-Printer-Attributes # modifying printer options
         Set-Job-Attributes
         Restart-Printer # etc
         >
    AuthType Default
    Require group cups_help_desk cups_admin
    Order deny,allow
  </Limit>

  #
  # Highest-level admin tasks: delete, add, set default, etc.
  #
  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Set-Default>
    AuthType Default
    Require group cups_admin
    Order deny,allow
  </Limit>

  #
  # All other operations not listed above
  #
  <Limit All>
    AuthType Default
    Require group cups_admin
    Order deny,allow
  </Limit>
</Policy>
```

### Notes:

* Where I used `Require group …`, that implies your system must map those group names (e.g. `cups_help_desk`, `cups_viewer`, `cups_admin`) into real OS groups or recognized groups in your authentication system (e.g. LDAP).
* For job submission, I allowed both `@OWNER` (the submitting user) **and** the groups `cups_viewer` / `cups_help_desk`. This means help desk or viewers can submit on behalf of others (if that’s what you want), or at least submit “regular” jobs.
* For “printer maintenance / self‑test / cleaning,” I used a more permissive group set. You might need to check CUPS’ exact IPP verbs for “clean print heads”, “self-test page”, etc., or tie them under generic operations like `Get-Printer-Attributes` or others.
* You might need to experiment (or refer to logs) to see exactly which IPP operations are triggered by certain GUI actions (e.g. cleaning, test page) to map them correctly.

---

## 4. Assign this policy to your printer(s)

After defining the policy, you need to apply it to printers. You can use the `lpadmin` command:

```bash
lpadmin -p your_printer_name -o printer-op-policy=restricted-print
```

Or via the CUPS web interface or config.

---

## 5. Test and adjust

* Enable verbose logging (or debug) to see which operations are being blocked or allowed (check `/var/log/cups/error_log`).
* Try actions as different role accounts and verify you get expected permissions or denials.
* Adjust your `<Limit>` listings if a certain action is not included or is controlled under another IPP verb.

---

If you like, I can build a **full working cups config snippet** for your scenario (with your listed operations exactly) that you can drop into your `cupsd.conf` (or include file). Do you want me to do that?

[1]: https://www.cups.org/doc/policies.html?utm_source=chatgpt.com "Managing Operation Policies"
