
## CoolPay for FakeBook

### description
interact with the CoolPay payments system via a command line interface

### dependencies
- 'ruby'
- 'rest_client'
- 'json'

### features
- Authenticate to Coolpay API
- Add recipients
- Send recipients money
- Check whether a payment was successful

### usage
execute the script..

> ruby coolpay.rb

..and following the on screen prompts

### help

```
welcome to Coolpay CLI for FakeBook!

type 'help' to see all user commands

help
Coolpay CLI for FakeBook: supported commands

  help  : this info
  add   : add recipient
  send  : send recipient money
  check : check a transaction's status
  reset : clear input
  exit  : exit application

```

### todo
- deal with potential illegal characters in names
- lookup up currency codes for validation
- accept wider variety of money strings for transaction amounts
- allow manual authentication
- use partial string aliases for supported commands
- add debug strings
- add prompt char, e.g '>'
- GUI
- deprecate legacy 'rest_client' for 'rest-client'
- fix 'reset' to clear screen

