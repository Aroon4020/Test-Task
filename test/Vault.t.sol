// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    address whale = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address stETHAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // stETH contract address on Ethereum Mainnet
    address eigenlayerDelegationManager =
        0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A;
    uint256 operatorPrivateKey = 0xabc123;
    address owner = address(1234);
    address alice = address(234);
    uint256 withdrawlDelay = 50400;
    address operator;
    Vault public vault;
    IERC20 stETH;

    //imoersonating stEth whale account because deal is failing on mainnet
    function setUp() public {
        stETH = IERC20(stETHAddress); // Initialize the stETH contract interface
        vault = new Vault(owner);
        operator = vm.addr(operatorPrivateKey);
    }

    function testDeposit() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1e18);
        vault.deposit(1 ether);
        uint256 bal = vault.balanceOf(whale);
        require(bal == 1 ether, "mismatch");
        vm.stopPrank();
    }

    function testDeposit2() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1e18);
        vault.deposit(1 ether);
        stETH.transfer(alice, 0.5 ether);
        vm.stopPrank();
        vm.startPrank(alice);
        stETH.approve(address(vault), 0.5 ether);
        vault.deposit(0.5 ether);
        vm.stopPrank();
    }

    function testDelagateTo() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1e18);
        vault.deposit(1 ether);
        vm.stopPrank();
        //register as operator
        _registerOperatorWith1271DelegationApprover(operator);
        bytes32 salt = 0x0;
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _delegateToOperatorWhoRequiresSig(
                address(vault),
                operator,
                salt
            );
        vm.startPrank(owner);
        vault.delegateTo(operator, approverSignatureAndExpiry, salt);
        vm.stopPrank();
    }

    function testUndelegate() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1e18);
        vault.deposit(1 ether);
        vm.stopPrank();
        _registerOperatorWith1271DelegationApprover(operator);
        bytes32 salt = 0x0;
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _delegateToOperatorWhoRequiresSig(
                address(vault),
                operator,
                salt
            );
        vm.startPrank(owner);
        vault.delegateTo(operator, approverSignatureAndExpiry, salt);
        vault.undelegate();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1e18);
        vault.deposit(1 ether);
        vm.stopPrank();
        _registerOperatorWith1271DelegationApprover(operator);
        bytes32 salt = 0x0;
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _delegateToOperatorWhoRequiresSig(
                address(vault),
                operator,
                salt
            );
        vm.startPrank(owner);
        vault.delegateTo(operator, approverSignatureAndExpiry, salt);
        (
            IStrategy[] memory strategies,
            uint256[] memory shares
        ) = IDelegationManager(eigenlayerDelegationManager)
                .getDelegatableShares(address(vault));
        vault.undelegate();
        IDelegationManager.Withdrawal
            memory withdrawal = _setUpCompleteQueuedWithdrawal(
                address(vault),
                address(vault),
                strategies,
                shares
            );
        vm.roll(block.number + withdrawlDelay);
        vault.withdrawToContract(withdrawal);
        vm.stopPrank();
    }

    function testRandomScenario1() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1 ether);
        vault.deposit(0.8 ether);
        _registerOperatorWith1271DelegationApprover(operator);
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _delegateToOperatorWhoRequiresSig(
                address(vault),
                operator,
                0x0
            );
        vm.startPrank(owner);
        vault.delegateTo(operator, approverSignatureAndExpiry, 0x0);
        (
            IStrategy[] memory strategies,
            uint256[] memory shares
        ) = IDelegationManager(eigenlayerDelegationManager)
                .getDelegatableShares(address(vault));

        vault.undelegate();

        IDelegationManager.Withdrawal
            memory withdrawal = _setUpCompleteQueuedWithdrawal(
                address(vault),
                address(vault),
                strategies,
                shares
            );

        vm.startPrank(whale);
        stETH.approve(address(vault), 1 ether);
        vm.roll(block.number + withdrawlDelay);
        vault.deposit(0.1 ether);
        vm.startPrank(owner);
        vault.withdrawToContract(withdrawal);
        (approverSignatureAndExpiry) = _delegateToOperatorWhoRequiresSig(
            address(vault),
            operator,
            "0x1"
        );
        vault.delegateTo(operator, approverSignatureAndExpiry, "0x1");
        vm.stopPrank();
    }

    function testRandomScenario2() public {
        vm.startPrank(whale);
        stETH.approve(address(vault), 1 ether);
        vault.deposit(0.8 ether);
        _registerOperatorWith1271DelegationApprover(operator);
        ISignatureUtils.SignatureWithExpiry
            memory approverSignatureAndExpiry = _delegateToOperatorWhoRequiresSig(
                address(vault),
                operator,
                0x0
            );
        vm.startPrank(owner);
        vault.delegateTo(operator, approverSignatureAndExpiry, 0x0);

        vault.undelegate();
        (approverSignatureAndExpiry) = _delegateToOperatorWhoRequiresSig(
            address(vault),
            operator,
            "0x1"
        );
        vault.delegateTo(operator, approverSignatureAndExpiry, "0x1");
        vm.stopPrank();
    }

    function _delegateToOperatorWhoRequiresSig(
        address staker,
        address _operator,
        bytes32 salt
    ) internal view returns (ISignatureUtils.SignatureWithExpiry memory) {
        uint256 expiry = type(uint256).max;
        return _getApproverSignature(staker, _operator, salt, expiry);
    }

    function _registerOperatorWith1271DelegationApprover(
        address _operator
    ) internal {
        IDelegationManager.OperatorDetails
            memory operatorDetails = IDelegationManager.OperatorDetails({
                earningsReceiver: address(vault),
                delegationApprover: _operator,
                stakerOptOutWindowBlocks: 0
            });
        _registerOperator(_operator, operatorDetails, "");
    }

    function _registerOperator(
        address _operator,
        IDelegationManager.OperatorDetails memory operatorDetails,
        string memory metadataURI
    ) internal {
        vm.startPrank(_operator);
        IDelegationManager(eigenlayerDelegationManager).registerAsOperator(
            operatorDetails,
            metadataURI
        );
    }

    function _getApproverSignature(
        address staker,
        address _operator,
        bytes32 salt,
        uint256 expiry
    )
        internal
        view
        returns (
            ISignatureUtils.SignatureWithExpiry
                memory approverSignatureAndExpiry
        )
    {
        approverSignatureAndExpiry.expiry = expiry;
        {
            bytes32 digestHash = IDelegationManager(eigenlayerDelegationManager)
                .calculateDelegationApprovalDigestHash(
                    staker,
                    _operator,
                    _operator,
                    salt,
                    expiry
                );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                operatorPrivateKey,
                digestHash
            );
            approverSignatureAndExpiry.signature = abi.encodePacked(r, s, v);
        }
        return approverSignatureAndExpiry;
    }

    function _setUpCompleteQueuedWithdrawal(
        address staker,
        address withdrawer,
        IStrategy[] memory strategies,
        uint256[] memory shares
    ) internal view returns (IDelegationManager.Withdrawal memory) {
        IDelegationManager.Withdrawal memory withdrawal = IDelegationManager
            .Withdrawal({
                staker: staker,
                delegatedTo: operator,
                withdrawer: withdrawer,
                nonce: 0,
                startBlock: uint32(block.number),
                strategies: strategies,
                shares: shares
            });
        return (withdrawal);
    }
}
