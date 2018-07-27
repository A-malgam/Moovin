pragma solidity ^0.4.21;
import "./TestMOOVIN.sol";
import "./LogContractBase.sol";

contract MOOVINCrowdsale is LogContractBase{
    address public Beneficiary;
    uint256 public SoftCapInMOOV;
    MOOVIN public TokenReward;
    uint256 public EarlyBuyerTokensInMOOV;
    uint256 public ICOTokensInMOOV;
    uint public AmoutRaisedInWei;
    uint256 public RewardValueOfEarlyBuyer;
    uint256 public RewardValueOfICO;
    uint public ICODeadline;
    uint256 public EarlyBuyerMoovTokenRaised;
    uint256 public ICOMoovTokenRaised;
    address public AddressOfMOOV;
	
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public autorizeEthereumToSpend;
    uint256[] public kycApprouved;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint amount,uint256 reward, bool isContribution);

    function MOOVINCrowdsale(
        address beneficiary,
        uint256 softCapInMOOV,
        uint256 earlyBuyerTokensInMOOV,
        uint256 icoTokensInMOOV,
        uint icoDurationInMinutes,
        uint256 earlyBuyerMoovTokenForEachEther,
        uint256 icoMoovTokenForEachEther,
        address addressOfMOOV
    ) public{
        //Address of wallet for receive Ethereum when ICO end.
        Beneficiary = beneficiary;
        ICOTokensInMOOV = icoTokensInMOOV * 1 ether;
        EarlyBuyerTokensInMOOV = earlyBuyerTokensInMOOV * 1 ether;
        SoftCapInMOOV = softCapInMOOV * 1 ether;
        ICODeadline = now + icoDurationInMinutes * 1 minutes;
        RewardValueOfEarlyBuyer = earlyBuyerMoovTokenForEachEther;
        RewardValueOfICO = icoMoovTokenForEachEther;
        AddressOfMOOV = addressOfMOOV;
        TokenReward = MOOVIN(AddressOfMOOV);
    }

    function setAutorizedEthereumToSpend(address[] addressList, uint256[] autorizedAmountList, uint nbAddress) public {
        require(msg.sender == Beneficiary);
        for (uint i = 0; i < nbAddress; i++) {
            address addr = address(addressList[i]);
            autorizeEthereumToSpend[addr] += autorizedAmountList[i];
            WriteLog("info","setAutorizedEthereumToSpend", "approuving");
            WriteLog("","setAutorizedEthereumToSpend",ToAsciiString(addr));
            WriteLog("","setAutorizedEthereumToSpend",uint256ToString(autorizeEthereumToSpend[addr]));
        }
        WriteLog("info","setAutorizedEthereumToSpend", "all approuve done");
    }


    function DistributeEarlyBuyerToken(uint256 amountInWei) private {
        WriteLog("info","DistributeEarlyBuyerToken amountInWei : ", uint256ToString(amountInWei));
        WriteLog("info","DistributeEarlyBuyerToken RewardValueOfEarlyBuyer : ", uint256ToString(RewardValueOfEarlyBuyer));
        WriteLog("info","DistributeEarlyBuyerToken EarlyBuyerTokensInMOOV : ", uint256ToString(EarlyBuyerTokensInMOOV));
        WriteLog("info","DistributeEarlyBuyerToken EarlyBuyerMoovTokenRaised : ", uint256ToString(EarlyBuyerMoovTokenRaised));
        uint256  transactionMoovToTransfert = amountInWei * RewardValueOfEarlyBuyer;
        WriteLog("info","DistributeEarlyBuyerToken transactionMoovToTransfert : ", uint256ToString(transactionMoovToTransfert));
        //There is enough EarlyBuyer token to distribute
        if((transactionMoovToTransfert+EarlyBuyerMoovTokenRaised) <= EarlyBuyerTokensInMOOV)
        {
            WriteLog("info","DistributeEarlyBuyerToken", "transactionMoovToTransfert+EarlyBuyerMoovTokenRaised) <= EarlyBuyerTokensInMOOV");
            EarlyBuyerMoovTokenRaised += transactionMoovToTransfert;
            TransfertReward(amountInWei,transactionMoovToTransfert);
        }
        else
        {
            WriteLog("info","DistributeEarlyBuyerToken", "not enough early buyer token");
            uint256 earlyBuyerMoovLeft = EarlyBuyerTokensInMOOV - EarlyBuyerMoovTokenRaised;
            //uint256 lastMoovToTransfert = transactionMoovToTransfert - earlyBuyerMoovLeft;
            uint256 nbEthForEarlyTokenLeft = earlyBuyerMoovLeft / RewardValueOfEarlyBuyer;
            uint256 EthTransactionLeftToReward = (transactionMoovToTransfert - earlyBuyerMoovLeft) / RewardValueOfEarlyBuyer;
            uint256 icoMOOVToTransfert = EthTransactionLeftToReward * RewardValueOfICO;
            
            WriteLog("info","DistributeEarlyBuyerToken earlyBuyerMoovLeft : ", uint256ToString(earlyBuyerMoovLeft));
            WriteLog("info","DistributeEarlyBuyerToken EthTransactionLeftToReward : ", uint256ToString(EthTransactionLeftToReward));
            WriteLog("info","DistributeEarlyBuyerToken ethAtEarlyTokenCost : ", uint256ToString(nbEthForEarlyTokenLeft));
            WriteLog("info","DistributeEarlyBuyerToken icoMOOVToTransfert : ", uint256ToString(icoMOOVToTransfert));
            WriteLog("info","DistributeEarlyBuyerToken ICOTokensInMOOV : ", uint256ToString(ICOTokensInMOOV));

            //Not enough Token to distribute
            if(icoMOOVToTransfert > ICOTokensInMOOV)
            {
                uint256 AllTransactionTokenToTRansfert = ICOTokensInMOOV + earlyBuyerMoovLeft;
                ICOMoovTokenRaised += ICOTokensInMOOV;
                uint256 amountToRefund = (icoMOOVToTransfert - ICOTokensInMOOV) / RewardValueOfICO;
                uint256 realAmount = amountInWei - amountToRefund;
                WriteLog("info","DistributeEarlyBuyerToken", "abort distribution");
                RefundSender(amountToRefund);
            }
            else
            {
                AllTransactionTokenToTRansfert = icoMOOVToTransfert + earlyBuyerMoovLeft;
                ICOMoovTokenRaised += icoMOOVToTransfert;
                realAmount = amountInWei;
            }
            EarlyBuyerMoovTokenRaised += earlyBuyerMoovLeft;
            TransfertReward(realAmount,AllTransactionTokenToTRansfert);
            WriteLog("info","DistributeEarlyBuyerToken EarlyBuyerMoovTokenRaised : ", uint256ToString(EarlyBuyerMoovTokenRaised));
            WriteLog("info","DistributeEarlyBuyerToken earlyBuyerMoovLeft : ", uint256ToString(earlyBuyerMoovLeft));
            WriteLog("info","DistributeEarlyBuyerToken icoMOOVToTransfert : ", uint256ToString(icoMOOVToTransfert));
            WriteLog("info","DistributeEarlyBuyerToken", "distribute last Early token plus some ICO token");
            
        }
    }
   

    function DistributeICOToken(uint256 amountInWei) private{
        uint256 moovToTransfert = amountInWei * RewardValueOfICO;
        if ((moovToTransfert+ICOMoovTokenRaised) <= ICOTokensInMOOV)
        {
            WriteLog("info","DistributeICOToken", "(moovToTransfert+ICOMoovTokenRaised) <= ICOTokensInMOOV");
            WriteLog("info","checkGoalReached amountInWei: ",uint256ToString(amountInWei));
            WriteLog("info","checkGoalReached moovToTransfert: ",uint256ToString(moovToTransfert));
            ICOMoovTokenRaised += moovToTransfert;
            TransfertReward(amountInWei,moovToTransfert);
        }
        else if(ICOMoovTokenRaised < ICOTokensInMOOV)
        {
            //Transfert all last ICO token and refund Eth because here we havent enough token for all Eth in transaction
            WriteLog("info","DistributeICOToken", "ICOMoovTokenRaised < ICOTokensInMOOV");
            //we calculate the reward to transfert to the sender.
            uint256 icoMoovLeft = ICOTokensInMOOV - ICOMoovTokenRaised;
            uint256 icoMoovOfTransaction = amountInWei * RewardValueOfICO;
            moovToTransfert = icoMoovLeft;            
            ICOMoovTokenRaised += moovToTransfert;
            WriteLog("info","checkGoalReached icoMoovLeft: ",uint256ToString(icoMoovLeft));
            WriteLog("info","checkGoalReached icoMoovOfTransaction: ",uint256ToString(icoMoovOfTransaction));
            WriteLog("info","checkGoalReached ICOMoovTokenRaised: ",uint256ToString(ICOMoovTokenRaised));
            TransfertReward(amountInWei,moovToTransfert);

            //we calulate the amount to refund to the sender because we have not enougth Ico MOOV token.
            uint256 moovToRefund = icoMoovOfTransaction - icoMoovLeft;
            uint256 ethToRefund = moovToRefund / RewardValueOfICO;
            WriteLog("info","checkGoalReached moovToRefund: ",uint256ToString(moovToRefund));
            WriteLog("info","checkGoalReached ethToRefund: ",uint256ToString(ethToRefund));
            RefundSender(ethToRefund);
        }
    }
    

    function TransfertReward(uint256 amountInWei, uint256 moovToTransfert) private{
        balanceOf[msg.sender] += amountInWei;
        WriteLog("","TransfertReward",uint256ToString(autorizeEthereumToSpend[msg.sender]));
        WriteLog("","TransfertReward",uint256ToString(msg.value));
        autorizeEthereumToSpend[msg.sender] -= msg.value;
        WriteLog("","TransfertReward",uint256ToString(autorizeEthereumToSpend[msg.sender]));
        AmoutRaisedInWei += amountInWei;
        bool resp = TokenReward.transferFrom(Beneficiary,msg.sender,moovToTransfert);
        if(resp){
            WriteLog("","TokenReward.transfer resp",boolToString(resp));
            emit FundTransfer(msg.sender, amountInWei, moovToTransfert, true);
        }
        WriteLog("info","TransfertReward", "TxRe_end");
    }

    function RefundSender(uint amountInWei) private {        
        msg.sender.transfer(amountInWei);
        emit FundTransfer(msg.sender, amountInWei, 0, false);
        WriteLog("info","RefundSender", "end");
    }

    function () payable public{
        require(ICOMoovTokenRaised < ICOTokensInMOOV);
        require(now < ICODeadline);
        require(autorizeEthereumToSpend[msg.sender] >= msg.value);
        uint256 amountInWei = msg.value;
        WriteLog("info","payable amountInWei : ", uint256ToString(amountInWei));
        WriteLog("info","payable EarlyBuyerTokensInMOOV : ", uint256ToString(EarlyBuyerTokensInMOOV));
        WriteLog("info","payable EarlyBuyerMoovTokenRaised : ", uint256ToString(EarlyBuyerMoovTokenRaised));
        if(EarlyBuyerTokensInMOOV > EarlyBuyerMoovTokenRaised) {
            WriteLog("info","payable","earlyToken");
            DistributeEarlyBuyerToken(amountInWei);
        }
        else
        {
            WriteLog("info","payable","icotoken");
            //the refund is check in the function DistributeICOToken. 
            DistributeICOToken(amountInWei);
        }
        WriteLog("info","payable","end");
    }

    modifier afterIcoDeadline() {if(now >= ICODeadline) _;}

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterIcoDeadline public{
        uint256 moovRaisedAmount = EarlyBuyerMoovTokenRaised + ICOMoovTokenRaised;
        WriteLog("info","checkGoalReached moovRaisedAmount: ",uint256ToString(moovRaisedAmount));
        WriteLog("info","checkGoalReached SoftCapInMOOV: ",uint256ToString(SoftCapInMOOV));
        if (moovRaisedAmount >= SoftCapInMOOV){
            fundingGoalReached = true;
            emit GoalReached(Beneficiary, moovRaisedAmount);
        }
        WriteLog("info","checkGoalReached","end");
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() afterIcoDeadline public{
        WriteLog("Info","safeWithdrawal fundingGoalReachd",boolToString(fundingGoalReached));
        WriteLog("info","safeWithdrawal beneficiary", ToAsciiString(Beneficiary));
        if (!fundingGoalReached) 
		{
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) 
			{
                RefundSender(amount);
                WriteLog("info","safeWithdrawal","RefundSender");  
            }
            WriteLog("info","safeWithdrawal","!fundingGoalReached");  
        }

        if (fundingGoalReached && Beneficiary == msg.sender) 
		{
            Beneficiary.transfer(AmoutRaisedInWei);
            emit FundTransfer(Beneficiary,AmoutRaisedInWei, 0, false);
            WriteLog("info","safeWithdrawal","fundingGoalReached && Beneficiary == msg.sender");  
        }   
        WriteLog("info","safeWithdrawal","end");  
    }
}