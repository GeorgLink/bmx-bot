# Bot requires CL features

## Manage Users

### Create User

    bmx user create --usermail=<USERMAIL> --password=<PASSWORD

**Expected JSON return:**
Same a Show User, important is USER_UUID

_NOTE:_ Restricted to admin users only?

### Show User Detail

Current syntax:

    bmx user show <USERMAIL>

Proposed syntax:

    bmx user show <USER_UUID>

_NOTE:_ currently, any user can see details on any other user. This needs to be restricted in the interface. It is okay for a user to see another user's account, active and past positions, active and past offers. HOWEVER, do not identify user by email but uuid! -- not important for bot, but for live system.

**Expected JSON return:**

- _user_ : USER_UUID
- usermail :  (only if looking at self or with admin permissions)
- balance : (only if looking at self or with admin permissions)

_NOTE:_ I suggest renaming the field 'uuid' to 'user' because uuid is used for all objects, not just users.

Not important, we need a separate statistics interface:
- number of active offers
- number of inactive offers (cancelled or matched)
- number of active positions
- number of inactive positions

_NOTE:_
I expect the list of offers and positions to get very long. Better create a new command for that.

### View Offers

Proposed syntax:

    bmx user offers <USER_UUID>

**Expected JSON return:**

- list of active OFFER_UUIDs

### View Positiions

Proposed syntax:

    bmx user positions <USER_UUID>

**Expected JSON return:**

- list of active POSITION_UUIDs

### Deposit Tokens
Needed to increase an accounts funds by N tokens.

Proposed syntax:

    bmx user deposit <N> <USER_UUID>

_NOTE:_ Restrict to central bank user only.

**Expected JSON return:**

- new balance amount

### Withdraw Tokens
Needed to reduce funds of account by N tokens.

Proposed syntax:

    bmx user withdraw <N> <USER_UUID>

_NOTE:_ Restrict to central bank user only.

**Expected JSON return:**

- new balance amount

## Manage Offers

### Create Buy Offer

Proposed Syntax:

    bmx offer buy --side=<FIXED/UNFIXED> --volume=<INTEGER> --price=<P> --issue=<ISSUE_UUID> --maturation=<TIMESTAMP> --allornothing=<BOOLEAN> --expiration=<TIMESTAMP>

**Parameters:**

- side : whether the offer for FIXED or UNFIXED side
- volume : number of contracts willing to buy
- price : value between 0 and 1 (don't know how many decimal places we should allow); upper bound, will accept cheaper prices
- issue : ID of issue
- maturation : TIMESTAMP  when the contract should be maturing
- allornothing : whether partial contracts can be formed
- expiration : TIMESTAMP when the offer is removed from the market if not matched by then

**Expected JSON return:**

- offer : OFFER_UUID

### Create Sell Offer

Proposed Syntax:
    bmx offer sell --position=<POSITION_UUID> --volume=<INTEGER> --price=<P> --allornothing=<BOOLEAN> --expiration=<TIMESTAMP>

**Parameter explanation:**

- position : ID of position to be resold
- volume : how much of the position shall be resold
- price : value between 0 and 1; lower bound, will accept higher prices
- expiration : TIMESTAMP when the offer is removed from the market if not matched by then

**Expected JSON return:**

- offer : OFFER_UUID

### Cancel Offer

Proposed Syntax:

    bmx offer cancel <OFFER_UUID>

**Expected JSON return:**

- offer : OFFER_UUID

### Show details of offer

Current Syntax:

    bmx offer show <OFFER_UUID>

**Expected JSON return:**

- offer : OFFER_UUID
- user : USER_UUID
- type : buy/sell
- side : FIXED/UNFIXED
- maturation : timestamp
- expiration : timestamp
- issue : ISSUE_UID
- repo : REPO_UUID
- price

### List Active Offers

Current Syntax:

    bmx offer list

**Expected JSON return:**
list of (same as 'bmx offer show')
- offer : OFFER_UUID
- user : USER_UUID
- type : buy/sell
- side : FIXED/UNFIXED
- maturation : timestamp
- expiration : timestamp
- issue : ISSUE_UID
- repo: REPO_UUID
- price

### Clone Offer

_NOTE:_ I don't see a need for this.

## Issue

### Show details of issue

Current Syntax:

    bmx issue show <ISSUE_UUID>

**Expected JSON return:**

- issue: ISSUE_UUID
- repo: REPO_UUID
- url : URL to issue-tracker issue
- oracle : what oracle evaluates this issue? - Is that the same as _type_ in the current implementation?
- created : timestamp when issue was created

These statistics outputs are important for modeling bot decisions:
- offers_sell_fixed : number of open fixed sell offers
- offers_buy_fixed : number of open fixed buy offers
- offers_sell_unfixed : number of open unfixed sell offers
- offers_buy_unfixed : number of open unfixed buy offers
- escrow : number of tokens in escrow for contracts on this issue
- contracts : number of contracts on this issue (equals half of all positions)
- last match price

A historical view will be interesting, but is low priority:
- contracts_fixed = number of contracts that evaluated fixed
- contracts_unfixed = number of contracts that evaluated unfixed
- contracts_total = number of contracts ever created
- escrow_fixed = tokens paid out to fixed positions holders
- escrow_unfixed = tokens paid out to unfixed position holders
- escrow_total = how much escrow was on this issue in total (= escrow_fixed + escrow_unfixed + escrow)
- offers_sell_fixed_total : total number of fixed sell offers ever created
- offers_buy_fixed_total : total number of fixed buy offers ever created
- offers_sell_unfixed_total : total number of unfixed sell offers ever created
- offers_buy_unfixed_total : total number of unfixed buy offers ever created
- offers_sell_fixed_expired : total number of expired fixed sell offers
- offers_buy_fixed_expired : total number of expired fixed buy offers
- offers_sell_unfixed_expired : total number of expired unfixed sell offers
- offers_buy_unfixed_expired : total number of expired unfixed buy offers

### List Issues

Current Syntax:

    bmx issue list

**Expected JSON return:**
list of (same as 'bmx issue show')
- issue : ISSUE_UUID
- title : Title of issue
- repo: REPO_UUID
- url : URL to issue-tracker issue
- oracle : what oracle evaluates this issue? - Is that the same as _type_ in the current implementation?
- created : timestamp when issue was created

I removed the statistics metrics here, see above.

### Search for issue

Proposed syntax:

    bmx issue search --repo=<REPO_UUID> --created_before=<TIMESTAMP> --created_after=<TIMESTAMP> --oracle=<ORACLE> --title=<STR>


**Expected JSON return:**
list of (same as 'bmx issue show')
- issue : ISSUE_UUID
- repo : REPO_UUID
- url : URL to issue-tracker issue
- oracle : what oracle evaluates this issue? - Is that the same as _type_ in the current implementation?
- created : timestamp when issue was created

I removed the statistics metrics here, see above.

## Repository

### Show Repository

Current syntax:
    bmx repo show <REPO_UUID>

**Expected JSON return:**
- repo : REPO_UUID
- url : link to repository
- oracle : (currently called _type_)q
- name : name of repository
### List Repositories

Current syntax:
    bmx repo list

**Expected JSON return:**
same as show repo

### List issues of Repository

Proposed syntax:
    bmx repo issues <REPO_UUID>

**Expected JSON return:**
same as 'bmx issue list' but filtered for this repo

## Position

### Show Position

Current syntax:
    bmx position show <POSITION_UUID>

**Expected JSON return:**
- position : POSITION_UUID
- contract : CONTRACT_UUID
- issue : ISSUE_ID (for convenience)
- repo : REPO_ID (for convenience)
- side : fixed/unfixed
- volume : number of positions
- price : price paid to acquire position
- user : USER_UUID who owns the position
- maturation : TIMESTAMP
