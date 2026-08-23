# 2. What the product is

Wolevo is a **package-forwarding and proxy-buying service** for Africa,
currently Ghana and Nigeria. Two flows converge on the same warehouse.

## Flow A — Shop on Wolevo (proxy buying)

The user browses US retailers *inside* Wolevo (Amazon, eBay, Fashion Nova,
Plug Tech, Best Buy, Sephora), or pastes a product link. Wolevo buys the item,
receives it at its own US warehouse, and ships it onward.

`Shop → Product → Cart → Checkout → Orders`

## Flow B — Ship for me (forwarding)

The user gets a **personal US address** and ships to it themselves — from any
US store, or via family in the States. They then register the tracking number
so Wolevo can match the parcel when it lands.

`Ship → register package → warehouse weighs → quote → pay → delivered`

## The locker ID is the whole product

This is the single most important thing to understand about the domain.

Every user shares **the same physical US address**:

```
20 Penn Mart Center
PMB302
New Castle, DE 19720
```

The only thing distinguishing one user's parcel from another's is their
**locker ID** (e.g. `DEMO1234`), which must appear on the package — in the
recipient name (`Wolevo DEMO1234`) or on address line 2.

That is why the app is so insistent about it:

- The address panel has a **copy button per field**, not one for the block
- There are two loud warning blocks: *"PMB302 must be on your address"* and
  *"Use this exact name"*
- There is a First/Last name split for retailers that won't take one field
- The Account tab's header card leads with the locker ID and a copy button

**Never soften or trim that copy.** A parcel arriving without the locker ID
genuinely cannot be matched to a user, and Wolevo says so explicitly:
*"we can't take responsibility for it."*

## Money is always dual-currency

Every price the user sees is shown in **USD and their local currency**
(GHS `₵` / NGN `₦`). The conversion happens **server-side** — the client never
does FX. That is enforced by the `Money` type, which carries `usd`,
`localAmount` and `localCurrency` together and has no "convert" method.

## Payment rails

Card, **Mobile Money (MoMo)** and **bank transfer**. No US card or dollar
account is required — this is a core selling point, not a footnote.

## Delivery promise

7–14 days from the moment items reach the US warehouse. Delivery *or* pickup.

> The live landing page says "7-12 days" in its hero and "7-14 days" everywhere
> else. We use **7-14** and flag the inconsistency in a code comment.
