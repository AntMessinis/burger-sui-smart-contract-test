module burger::burger {
    use sui::object::{Self,Info};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};

    // Best burgers are made with brioche bread
    struct BriocheBread has key, store{
        info: Info
    }

    // Fresh tomato always has a place in a burger
    struct Tomato has key, store {
        info: Info
    }

    // One of the best cheeses 
    struct CheddarCheese has key, store {
        info: Info
    }

    //No beef no burger. The most important ingridient
    struct Beef has key, store {
        info: Info
    }

    // Raw or caramelized
    struct Onion has key, store {
        info: Info
    }

    struct Burger has key, store{
        info: Info,
        bread: BriocheBread,
        tomato: Tomato,
        onion: Onion,
        burger: Beef,
        cheese: CheddarCheese,
    }

    struct DeliveryBox has key{
        info: Info,
        food: Burger,
        delivery_for: address
    }

    struct BurgerShop has key{
        info: Info,
        burger_price: u64,
        balance: Balance<SUI>
    }

    struct BurgerShopOwner has key{
        info: Info
    }

    // Error code for when the customer doesn't have enough money
    const ENotEnoughMoney:u64 = 0;

    // Error code for when you are holding someone else's burger
    const ENotYourBurger:u64 = 1;

    //Error code for empty shop's balance
    const ENoProfits:u64 = 2;

    fun init(ctx: &mut TxContext){
        //Create a BurgerShopOwner Capability
        //and transfer it to the owner
        transfer::transfer(
            BurgerShopOwner{
                info: object::new(ctx)
            }, tx_context::sender(ctx)
        );

        //Create a BurgerShop and share it to make in
        //accessible to everyone
        transfer::share_object(
            BurgerShop{
                info: object::new(ctx),
                burger_price: 55,
                balance: balance::zero()
            }
        )
    }

    // Public function that allows people with money to buy the best burger in town
    public entry fun buy_burger(shop: &mut BurgerShop, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        //Check if the amount of money are enough to buy a burger
        //If they are less abort
        assert!(coin::value(payment) >= shop.burger_price, ENotEnoughMoney);

        //Take amount of money that corresponds to burger's price and put them in the shop's balance
        let money_for_burger = coin::balance_mut(payment);
        let paid = balance::split(money_for_burger, shop.burger_price);

        balance::join(&mut shop.balance, paid);

        //Cook a burger
        let burger = cook_burger(ctx);

        //Put in the delivery box
        let delivery = package_burger(ctx, burger);

        //Deliver it to customer
        transfer::transfer(delivery, tx_context::sender(ctx))
    }

    //Since we only use fresh ingredient we have to buy them every time we need to cook a burger

    fun buy_bread(ctx: &mut TxContext): BriocheBread {
        BriocheBread{
            info: object::new(ctx)
        }
    }

    fun buy_tomato(ctx: &mut TxContext): Tomato {
        Tomato {
            info: object::new(ctx)
        }
    }

    fun buy_onion(ctx: &mut TxContext): Onion {
        Onion {
            info: object::new(ctx)
        }
    }

    fun buy_beef(ctx: &mut TxContext): Beef {
        Beef {
            info: object::new(ctx)
        }
    }

    fun buy_cheddar(ctx: &mut TxContext): CheddarCheese {
        CheddarCheese {
            info: object::new(ctx)
        }
    }

    //Burger Assemble
    fun cook_burger(ctx: &mut TxContext): Burger {
        Burger{
            info: object::new(ctx),
            bread: buy_bread(ctx),
            tomato: buy_tomato(ctx),
            onion: buy_onion(ctx),
            burger: buy_beef(ctx),
            cheese: buy_cheddar(ctx)
        }
    }

    // Putting burger in a box 
    fun package_burger(ctx: &mut TxContext, food: Burger): DeliveryBox {
        DeliveryBox {
            info: object::new(ctx),
            food,
            delivery_for: tx_context::sender(ctx)
        }
    }

    // Public function that allows the person holding the package to unwrap it 
    public fun unpack_burger(delivery: DeliveryBox, ctx: &mut TxContext) {
        // You can't unpack it if it's not your burger
        assert!(delivery.delivery_for == tx_context::sender(ctx), ENotYourBurger);
        
        let DeliveryBox {
            info: delivery_id,
            food,
            delivery_for: _
        } = delivery;

        object::delete(delivery_id);
        transfer::transfer(food, tx_context::sender(ctx))
    }


    public entry fun collect_profits(_cap: &BurgerShopOwner, shop: &mut BurgerShop, ctx: &mut TxContext){
        //Check if the burger shop has profits
        let profits = balance::value(&shop.balance);
        assert!(profits > 0, ENoProfits);

        // Take money from shop's balance and transfer it to owner
        let money = coin::take(&mut shop.balance, profits, ctx);
        
        transfer::transfer(money, tx_context::sender(ctx))
    }
}