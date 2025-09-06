# Mutliple Tier User Security


- In the last article we talked about accessing an Linux application running throught SSH and how to secure the SSH and now we are going to look at securing the users

- Most Linux servers I setup have up to two classes of users, Linux Admin and Application Admins and from a security point of view can have ligh levels of harding but what happens when other users are added into the mix?
- business users like application users from finance, sales, administration, HR, and marketing, etc where a users is assigned a device
- include mobile computers/handheld terminals like RF guns, barcode readers, and QR scanners where device could be used by more than one user
- Application developers which create and maintian the application being used
- System admin werther it be Cloud Engineer, DevOps Engineer, or Site Reliability Engineer (SRE) who need the make changes to the OS level
- Each of these user interact with the application/OS different and need to have differnt security

## Isn't Security the same for all
- It may seem wierd today to still have these type of security conversation butit still happens because
  - IT want to make sure infrusture invetments make by the busiess stay secure
  - Business leader and to make the work enviroment easier to use for the employees
- Both are valid goals and a balance must be found.
- mobile computers/handheld terminals are a great example of this.
- Business needs are to have simpler password with device with smallkeyboard and limited character access
- IT want to secure a shared device used by multiple users and is left sitting away from where the users are, it is almost the definition of device waiting to be exploited
- Over the next few article we will look into these concerns

## Password and Account Expiration
- Password are start to see interesting changes, with NIST SP 800-63B focus more stronger password and breach monitoring than password expiration  but the 60 to 90 day rules is still out there.
- The account expiration is the less talked about but the more important since it leaves wholes for attackers.
- when setting up rules for these, should all users have the same setup?
- I first thought was no, but I was suprised by the answer.

## mobile computers/handheld terminals
- For devices I see are the most worrious, I was surprised by that best practice suggest
  - No expiring password or 180 to 365 day password rotation
  - Accounts never expire
- when you look into the reason, it start to make sense
- these are usually business critical device
- To migated the risk, the users on these device need extra steps to setup on the linux device
  - the business app running through SSH should be a scaled down version only allow the functionlity needed
  - the Match/ForceCommand sould be used to restrict these users
  - If device are being used on isolated subnet, then that should be added to SSH match block.
- I recently was in a meeting where a similar topic was brought up.
  - I found myself talk more like a applicaton admin than a Linux admin.
  - Taking that application admin hat off and relooking at these security suggestion you start to see if:
    - I can restrict what a user can run
    - ensure that can not get outside the application
    - monitor the SSH log
    - I can see where these policies make sense but it still bugs me
```bash
## account never expires
sudo usermod -e '' username

# Disable password aging entirely
sudo chage -M 99999 username

# Require password change every 180 days
sudo chage -M 180 username
```

## business users
- The best practices were what I expected
  - Password expiration: 60–90 days if password expiration is used
  - Accounts expire based on:
    - seaonal worker/temperation works end date autoically set
    - contractor - set to end of contract
  - Employees - Use locked vs expired accounts
    - after 45 days inactivity lock the account
    - on terminated, on leave, or suspected compromise
```bash
## Manual locking an account
# Lock account with passwd
sudo passwd -l username

# or 
# Lock account with usermod
sudo usermod -L username

# Unlock account with passwd
sudo passwd -u username
# or
# Unlock account with usermod
sudo usermod -U username
```
- MFA and SSH at a business user level still seems to be a holdout, not because Linux cannot do it but more HR policies and needing external device
- SSH auth would be nice but because a logistic nightmare on a large group of not technical users. 


## Application developers and Admin
- The rules now be tighter because these users start having elevated access across multiple enviroments
- This makes then target for attacks
- Password expiration: 30–60 days if password expiration is used
- Like business users, lock is perferred over expired, but 30 to 45 days

```bash

## inactivity lock of 30 days
sudo chage -I 30 username
```
- The big change over the other uses MFA and/or SSH Auth  are being used
- user have a techincal backgroup so SSH generation and rotation is not is issue


## System Administrators
- the best practiced did suprise me, with Password expiration: 15-30 days if password expiration is used
- I've never had such a short expiration time frame
- Because of access, password vaults are started to be used to store and rotate password
- SSH Auth key or short-lived SSH certificates are beinbg used
- MFA is starting to become a most and not a extra
- lock is perferred over expired, but 15 to 30 days
```bash
## How to find inactive accounts
## No logins in 30 or more days
sudo lastlog -b 30
``` 

- Overall, most of what I found was expect but there were a few surprises.
- As I write this, is this article really needed, yes.
- A lot of the places I've worked at or in talking with other people, these type of standards are not outline in a document.
- The first step would be to create a stands document of what policies are work towards improving the security
- A lot the time the current state is so far off the desired security state, that companies to implemet changes.
- But when small changes happen on a regular bases, the gap between were you are at and when you want to be becomes smaller all the time.

Next we will look at muitple tier password policy.
