// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// interface IERC20 {
//   function balanceOf(address account) external view returns (uint256);
//   function transfer(address recipient, uint256 amount) external returns (bool);
//   function allowance(address owner, address spender) external view returns (uint256);
//   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
// }


contract LendingPool is Ownable, ReentrancyGuard {

    //  USDC token address
    IERC20 public usdc;

    uint256 private loanIdCounter = 0;

    enum LoanStatus {
        Init,
        WaitingForTokens,
        Approved,
        PaidBack,
        Defaulted,
        Closed,
        Settled,
        Liquidated,
        Frozen,
        Canceled,
        Failed,
        InProgress,
        Completed,
        WaitingForLender,
        WaitingForPayback
    }


    // Loans
    struct Loan {
        LoanStatus loanStatus;
        uint256 repaidAmount;
        uint256 loanAmount;
    }


    // lending activity struct
    struct LendingActivity {
        uint depositUSDC;
        uint timeDeposit;
        uint rewardRT; // Assuming RT stands for RelicToken
    }

    struct CollateralActivity {
        uint depositETH;
        uint timeDeposit;
        uint rewardRT;
    }

    // borrowers activity struct
    struct BorrowingActivity {
        uint availableUSDC;
        uint withdrawnUSDC;
        uint timeWithdrawn;
        uint interestFee;
    }

    // mapping of borrower address to their lending activity
    mapping(address => LendingActivity) public lendingActivity;
    mapping(address => CollateralActivity) public collateralActivity;
    mapping(address => BorrowingActivity) public borrowingActivity;
    mapping(address => LoanStatus) public loanStatuses;
    mapping(uint256 => Loan) public Loans;

    // lending pool address, amount of tokens in the Lending Pool,
    // the amount of tokens in the Borrowing Pool
    // the amount of tokens in the Collateral Pool, pool
    // total number of active borrowers and the total number of active lenders
    uint public numBorrowers = 0;
    uint public numLenders = 0;
    uint public numLendingPool = 0;
    uint public numBorrowingPool = 0;
    uint public numCollateralPool = 0;
    uint public totalLendingPool = 0;
    uint public totalBorrowingPool = 0;
    uint public totalCollateralPool = 0;
    address public lendingPoolAddress;
    uint public lendingPoolAmount;


    event DepositedToLendingPool(address indexed _user, uint256 _amount);
    event WithdrawFromLendingPool(address indexed _user, uint256 _amount);
    event UserStartedLending(address indexed _user, uint256 _amount);
    event UserStoppedLending(address indexed _user, uint256 _amount);
    event StartedCollateralizing(address indexed _user, uint256 _amount);
    event DepositedToCollateralPool(address indexed _user, uint256 _amount);
    event WithdrawFromCollateralPool(address indexed _user, uint256 _amount);
    event Borrowed(address indexed _user, uint256 _amount);
    event Repaid(address indexed _user, uint256 _amount);
    event Defaulted(address indexed borrower, uint256 amount);
    event LoanCanceled(address indexed borrower, uint256 amount);


    /*** Modifiers ******************/

    constructor(address initialOwner) Ownable(initialOwner) ReentrancyGuard() {
        // Your constructor's code here
    }

    function setUsdcAddress(address _usdcAddress) external onlyOwner {
        usdc = IERC20(_usdcAddress);
    }

    // set lending pool address when contract is deployed



    // function depoist USDC - can be made dynamic for Other satable i.e cUSD, DAI, USDT
    function depositToLendingPool(uint _amount) external {
        require(usdc.allowance(msg.sender, address(this)) >= _amount, "Approve USDC first");
        require(usdc.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        lendingPoolAmount += _amount;
        totalLendingPool += _amount;
        emit DepositedToLendingPool(msg.sender, _amount);
    }

    // function withdraw USDC from Lending Pool
    function withdrawFromLendingPool(uint _amount) external {
        require(lendingPoolAmount >= _amount, "Insufficient funds in the Lending Pool");
        require(usdc.transfer(msg.sender, _amount), "Transfer failed");
        lendingPoolAmount -= _amount;
        totalLendingPool -= _amount;
        emit WithdrawFromLendingPool(msg.sender, _amount);
    }

    // start lending by approving USDC to be transferred to the Lending Pool and setting lend amount
    function startLending(uint _amount) external {
        require(usdc.allowance(msg.sender, address(this)) >= _amount, "Approve USDC first");
        require(usdc.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        lendingActivity[msg.sender].depositUSDC = _amount;
        lendingActivity[msg.sender].timeDeposit = block.number;
        numLenders += 1;
        emit UserStartedLending(msg.sender, _amount);
    }

    // stop lending by withdrawing USDC from the Lending Pool
    function stopLending() public {
        require(lendingActivity[msg.sender].depositUSDC > 0, "No funds to withdraw");
        require(usdc.transfer(msg.sender, lendingActivity[msg.sender].depositUSDC), "Transfer failed");
        lendingActivity[msg.sender].depositUSDC = 0;
        lendingActivity[msg.sender].timeDeposit = 0;
        numLenders -= 1;
        emit UserStoppedLending(msg.sender, lendingActivity[msg.sender].depositUSDC);
    }

    // function to start collateralizing by depositing tokens into this contract as Collateral
    function addCollateral(uint256 _amount) public  {
        require(_amount > 0, "must be greater then zero");
        collateralActivity[msg.sender].depositETH = _amount;
        require(usdc.approve(address(this), _amount), "Approve USDC first");
        require(usdc.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        collateralActivity[msg.sender].timeDeposit = block.number;
        numCollateralPool += 1;
        totalCollateralPool += _amount;
        emit StartedCollateralizing(msg.sender, _amount);
    }


    // initiating a loan, assuming initial repaid value = 0
    function createLoanRequest(uint256 _amount, address _collateral) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(collateralActivity[msg.sender].depositETH > 0, "No collateral deposited");
        require(usdc.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        uint256 _loanId = loanIdCounter++;
        // Ensure _loanId is unique or hasn't been used before to prevent overwriting
        require(Loans[_loanId].loanAmount == 0, "Loan ID already exists");
        borrowingActivity[msg.sender].availableUSDC = _amount;
        borrowingActivity[msg.sender].timeWithdrawn = block.number;
        Loans[_loanId] = Loan({
            loanStatus: LoanStatus.Init,
            repaidAmount: 0,
            loanAmount: _amount
        });
        numBorrowers += 1;
        totalBorrowingPool += _amount;
        emit Borrowed(msg.sender, _amount);
    }

    // withdraw funds by the borrower
    function withdrawFunds(uint256 _amount) public {
        require(borrowingActivity[msg.sender].availableUSDC > 0, "No funds to withdraw");
        require(usdc.transfer(msg.sender, _amount), "Transfer failed");
        borrowingActivity[msg.sender].withdrawnUSDC = _amount;
        borrowingActivity[msg.sender].timeWithdrawn = block.number;
        emit Borrowed(msg.sender, _amount);
    }


    // repaying USDC loan
    function repayLoan(uint256 _loanId, uint256 _amount) public {
        require(borrowingActivity[msg.sender].availableUSDC > 0, "No loan to repay");
        require(usdc.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        borrowingActivity[msg.sender].availableUSDC -= _amount;

        Loans[_loanId].loanStatus = LoanStatus.PaidBack;
        Loans[_loanId].repaidAmount += _amount;
        if (Loans[_loanId].repaidAmount == Loans[_loanId].loanAmount) {
            Loans[_loanId].loanStatus = LoanStatus.Closed;
        }

        totalBorrowingPool -= _amount;
        emit Repaid(msg.sender, _amount);
    }


    // handling defaults and liquidations
    function handleDefault(uint256 _loanId, address _borrower) public {
        require(borrowingActivity[_borrower].availableUSDC > 0, "No loan to default");
        borrowingActivity[_borrower].availableUSDC = 0;
        Loans[_loanId].loanStatus = LoanStatus.Defaulted;
        totalBorrowingPool -= borrowingActivity[_borrower].availableUSDC;
        emit Defaulted(_borrower, borrowingActivity[_borrower].availableUSDC);
    }

    // canceling a loan request
    function cancelLoan(uint256 _loanId) public {
        require(borrowingActivity[msg.sender].availableUSDC > 0, "No loan to cancel");
        borrowingActivity[msg.sender].availableUSDC = 0;
        Loans[_loanId].loanStatus = LoanStatus.Canceled;
        totalBorrowingPool -= borrowingActivity[msg.sender].availableUSDC;
        emit LoanCanceled(msg.sender, borrowingActivity[msg.sender].availableUSDC);
    }


    // get functions here
    function getLenderDeposit(address lender) public view returns (uint) {
        return lendingActivity[lender].depositUSDC;
    }

    // get the total collat
    function getCollateralDeposit(address _collateral) public view returns (uint) {
        return collateralActivity[_collateral].depositETH;
    }






    // struct Borrower {
    //     uint depositLendingUSDC; // USDC deposited (Lending)
    //     uint256 timeDepositLendingUSDC;     // Time of USDC deposit (Lending)
    //     uint256 rewardDepositLendingUSDC;   // USDC rewards from deposit (Lending) given as RelicToken(RT) OR even LISK
    //     uint256 depositCollateralETH;           // ETH deposited (Collateral)
    //     uint256 timeDepositCollateralETH;      // Time of ETH deposit (Collateral)
    //     uint256 rewardDepositCollateralETH;    // USDC rewards from deposit (Collateral) given as RelicToken(RT)
    //     uint256 availableBorrowingUSDC;        // Available USDC to borrow 80% of ETH value in USDC (Borrowing)
    //     uint256 withdrawBorrowingUSDC;         // USDC withdrawn (Borrowing)
    //     uint256 timeWithdrawBorrowingUSDC;    // Time of USDC withdraw (Borrowing)
    //     uint256 interestFee;            // Interest USDC fee for borrowing
    // }

    

    // what are the functions that need to be implemented?
    // function deposit() external;
    // function withdraw() external;
    // function getBalance() external view returns (uint256);
    // function getBorrowBalance() external view returns (uint256);
    // function getInterestAccrued() external view returns (uint256);
    // function getReserveConfiguration() external view returns (address configurator, uint64 reserveFactorMantissa, uint40 borrowCapMantissa);
    // function getUserConfiguration() external view returns (address configurator, uint64 liquidation threshold, uint40 health factor, uint40 lastHealthCheckTimestamp);

    // address public lendingPoolAddress;

    // // events declaration
    // event Deposited(address indexed _reserve, address indexed _user, uint256 _amount);
    // event Withdrawed(address indexed _reserve, address indexed _user, uint256 _amount);
    // event EmergencyWithdrawal(address indexed _reserve, address indexed _to, uint256 _amount);

    // function setLendingPoolAddress(address _lendingPoolAddress) external onlyOwner {
    //     lendingPoolAddress = _lendingPoolAddress;
    // }

    // function safeDeposit(address _reserve, uint256 _amount, uint16 _referralCode) external {
    //     require(IERC20(_reserve).approve(address(lendingPoolAddress), _amount), "Approval failed");

    //     ILendingPool(lendingPoolAddress).deposit(_reserve, _amount, msg.sender, _referralCode);

    //     // Emit an event or add additional logic as needed
    //     emit Deposited(_reserve, msg.sender, _amount);
    // }

    // // function check deposit balance
    // function checkDepositBalance(address _reserve, address _user) external view returns (uint256) {
    //     // Assuming there's a function in ILendingPool to get a user's deposit balance
    //     // If not available directly, this might involve interacting with the respective aToken contract for _reserve
    //     uint256 depositBalance = ILendingPool.getBalance(_reserve, _user);
    //     return depositBalance;
    // }

    // // safe  withdraw function that checks the status of the transaction and emits an event if successful
    // function safeWithdraw(address _reserve, uint256 _amount) external {
    //     uint256 balanceBefore = IERC20(_reserve).balanceOf(msg.sender);
    //     ILendingPool.withdraw(_reserve, _amount, payable(msg.sender));
    //     uint256 balanceAfter = IERC20(_reserve).balanceOf(msg.sender);

    //     require(balanceAfter > balanceBefore, "Withdrawal failed or no funds received");

    //     // Emit an event or add additional logic as needed
    //     emit Withdrawed(_reserve, msg.sender, _amount);
    // }

    // // emergency withdraw function
    // function emergencyWithdraw(address _reserve, uint256 _amount, address payable _to) external onlyOwner {
    //     ILendingPool.withdraw(_reserve, _amount, _to);
    //     emit EmergencyWithdrawal(_reserve, _to, _amount);
    // }

}

