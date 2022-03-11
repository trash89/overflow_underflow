from brownie import accounts, Attack, TimeLock


def main():
    print("Deploying TimeLock...")
    tl = TimeLock.deploy({"from": accounts[0]})
    print(f"Timelock deployed at {tl}")

    print("Deploying Attack with the address of TimeLock...")
    att = Attack.deploy(tl.address, {"from": accounts[0]})
    print(f"Attack deployed at {att}")

    print("Calling Attack.attack() with 1 ether...")
    tx = att.attack({"from": accounts[0], "value": "1 ether"})
    tx.wait(1)
