const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LendingPool Contract", function () {
  let LendingPool;
  let lendingPool;
  let owner;
  let user;
  let otherAccount;
  let reserveToken;

  beforeEach(async function () {
    [owner, user, otherAccount] = await ethers.getSigners();

    // Mock Reserve Token setup
    const ReserveToken = await ethers.getContractFactory("MockERC20");
    reserveToken = await ReserveToken.deploy("Mock Reserve Token", "MRT", ethers.utils.parseEther("10000"));
    await reserveToken.deployed();

    // Deploying LendingPool contract
    LendingPool = await ethers.getContractFactory("LendingPool");
    lendingPool = await LendingPool.deploy();
    await lendingPool.deployed();
    lendingPool.setLendingPoolAddress(reserveToken.address); // Assuming this setter exists for demonstration

    // Assuming users have enough reserveToken to interact with LendingPool
    await reserveToken.transfer(user.address, ethers.utils.parseEther("1000"));
    await reserveToken.connect(user).approve(lendingPool.address, ethers.utils.parseEther("1000"));
  });

  describe("Deposit", function () {
    it("Should emit Deposited event upon deposit", async function () {
      const depositAmount = ethers.utils.parseEther("100");
      await expect(lendingPool.connect(user).safeDeposit(reserveToken.address, depositAmount, 0))
        .to.emit(lendingPool, "Deposited")
        .withArgs(reserveToken.address, user.address, depositAmount);
    });
  });

  describe("Withdraw", function () {
    it("Should emit Withdrawed event upon withdrawal", async function () {
      const depositAmount = ethers.utils.parseEther("100");
      const withdrawAmount = ethers.utils.parseEther("50");

      // User deposits first
      await lendingPool.connect(user).safeDeposit(reserveToken.address, depositAmount, 0);

      // Then withdraws
      await expect(lendingPool.connect(user).safeWithdraw(reserveToken.address, withdrawAmount))
        .to.emit(lendingPool, "Withdrawed")
        .withArgs(reserveToken.address, user.address, withdrawAmount);
    });
  });

  describe("Emergency Withdraw", function () {
    it("Should allow only owner to perform emergency withdrawals", async function () {
      const emergencyWithdrawAmount = ethers.utils.parseEther("50");
      await expect(lendingPool.connect(otherAccount).emergencyWithdraw(reserveToken.address, emergencyWithdrawAmount, otherAccount.address))
        .to.be.revertedWith("Ownable: caller is not the owner");
      
      await expect(lendingPool.connect(owner).emergencyWithdraw(reserveToken.address, emergencyWithdrawAmount, owner.address))
        .to.emit(lendingPool, "EmergencyWithdrawal")
        .withArgs(reserveToken.address, owner.address, emergencyWithdrawAmount);
    });
  });

  // Additional tests as needed...
});
