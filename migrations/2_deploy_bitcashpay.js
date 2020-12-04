const BitcashPay = artifacts.require("BitcashPay");
const BitcashPayTokenPreSale = artifacts.require("./BitcashPayTokenPreSale");
const SaleRoundOne = artifacts.require("./BitcashPaySaleRoundOne");
const SaleRoundTwo = artifacts.require("./BitcashPaySaleRoundTwo");
const SaleRoundThree = artifacts.require("./BitcashPaySaleRoundThree");

const TokenStaking = artifacts.require("./BitcashPayStaking");
const Airdropper = artifacts.require('./BitcashPayAirdropper');

module.exports = async function(deployer) {
    
    // deployer.deploy(BitcashPay)
    //     .then(token => {
    //         return deployer.deploy(Airdropper, token.address);
    //     })
    return await deployer.deploy(
        Airdropper,
        "0xe047705117Eb07e712C3d684f5B18E74577e83aC"
    );
};
