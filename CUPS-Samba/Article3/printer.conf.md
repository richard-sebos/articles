

```bash
### Before changes'
<Printer Cups-PDF>
  PrinterId 10
  UUID urn:uuid:78caf5ef-d284-351c-7e16-246e3e561eea
  Info Cups-PDF
  MakeModel Generic CUPS-PDF Printer (no options)
  DeviceURI cups-pdf:/
  State Idle
  StateTime 1759285102
  ConfigTime 1759284654
  Type 12644428
  Accepting Yes
  Shared Yes
  JobSheets none none
  QuotaPeriod 0
  PageLimit 0
  KLimit 0
  OpPolicy default
  ErrorPolicy stop-printer
</Printer>

```


```bash
## after changes
<Printer Cups-PDF>
  PrinterId 10
  UUID urn:uuid:78caf5ef-d284-351c-7e16-246e3e561eea
  Info Secure PDF Printer
  MakeModel Generic CUPS-PDF Printer (no options)
  DeviceURI cups-pdf:/
  State Idle
  Accepting Yes
  Shared No
  JobSheets none none

  # Apply quotas to prevent DoS
  QuotaPeriod 86400         # 1 day
  PageLimit 100             # Max 100 pages per day per user
  KLimit 20480              # ~20 MB per job

  # Use custom policies
  OpPolicy restricted-print
  ErrorPolicy stop-printer
</Printer>

# Per-printer access rules (cupsd.conf)
<Location /printers/Cups-PDF>
  AuthType Basic
  Require group pdf_users
  Order deny,allow
  Allow from 192.168.35.0/24
  Deny from all
</Location>

# Define restricted operation policy
<Policy restricted-print>
  <Limit Send-Document Send-URI Print-Job Print-URI>
    AuthType Default
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit All>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
</Policy>

```
