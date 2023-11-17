# AutoCraftingHats

**Warning that this does delete the item on the cursor, and calls clear cursor before each time it deletes a vanity item.  But if you are running something like a bag sort or anything else that uses the cursor at the same time, bad things can happen.**

Checks inventory for hat+master crafter stuff, if not already there or equipped, grabs from vanity.

Re-equips initial gear and deletes all vanity hats and master crafter stuff from bags when you close a tradeskill window.

If this is useful to others, I'll add some stuff from TODO.  

## TODO
* toggle auto-delete
* whitelist hats(eg for herbalism)
* immediately re-equip old hat
* check for hat buff before equipping with min duration
* ignore master crafter stuff
* equip skinner/herb/mining hat based on tooltip

the long initial delay(1s) before anything is grabbed is because I use TSM and I'm trying to work around its hitching issue.  Will add settings for that too
