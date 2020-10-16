pragma solidity ^0.5.0;

import "./yInsure.sol";

contract IyNFT is IERC721 {
    function submitClaim(uint256) external;
    function redeemClaim(uint256) external;
}

contract wyInsure is ERC721Full("Wrapped yInsureNFT", "wyNFT"), Ownable, ReentrancyGuard {
    yInsure ynft = yInsure(address(0x181Aea6936B407514ebFC0754A37704eB8d98F91));
    bytes4 internal constant ethCurrency = "ETH";

    function mint(uint256 tokenId) public {
        ynft.safeTransferFrom(msg.sender, address(this), tokenId);
        ynft.approve(msg.sender, tokenId);
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) public onlyTokenApprovedOrOwner(tokenId) {
        ynft.transferFrom(address(this), msg.sender, tokenId);
        _burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyTokenApprovedOrOwner(tokenId) {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    // Arguments to be passed as coverDetails, from the quote api:
    //    coverDetails[0] = coverAmount;
    //    coverDetails[1] = coverPrice;
    //    coverDetails[2] = coverPriceNXM;
    //    coverDetails[3] = expireTime;
    //    coverDetails[4] = generationTime;
    function buyCover(
        address coveredContractAddress,
        bytes4 coverCurrency,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        ynft.buyCover.value(msg.value)(coveredContractAddress, coverCurrency, coverDetails, coverPeriod, _v, _r, _s);
                
        // mint token
        uint256 tokenId = ynft.totalSupply() - 1;
        _mint(msg.sender, tokenId);
    }

    function submitClaim(uint256 tokenId) external onlyTokenApprovedOrOwner(tokenId) {
        ynft.submitClaim(tokenId);
    }

    function redeemClaim(uint256 tokenId) public onlyTokenApprovedOrOwner(tokenId) nonReentrant {
        uint coverId;
        bytes4 coverCurrency;
        (,coverCurrency,,,,,,coverId,,) = ynft.tokens(tokenId); 

        uint sumAssured;
        (,,sumAssured,,) = getCover(coverId);

        ynft.redeemClaim(tokenId);
        
        _burn(tokenId);
        _sendAssuredSum(coverCurrency, sumAssured);
    }

    function _sendAssuredSum(bytes4 coverCurrency, uint sumAssured) internal {
        if (coverCurrency == ethCurrency) {
            msg.sender.transfer(sumAssured);
        } else {
            IERC20 erc20 = IERC20(_getCurrencyAssetAddress(coverCurrency));
            require(erc20.transfer(msg.sender, sumAssured), "Transfer failed");
        }
    }

    function _getCurrencyAssetAddress(bytes4 currency) internal view returns (address) {
        PoolData pd = PoolData(ynft.nxMaster().getLatestAddress("PD"));
        return pd.getCurrencyAssetAddress(currency);
    }

    function getCover(
        uint coverId
    ) internal view returns (
        uint cid,
        uint8 status,
        uint sumAssured,
        uint16 coverPeriod,
        uint validUntil
    ) {
        QuotationData quotationData = QuotationData(ynft.nxMaster().getLatestAddress("QD"));
        return quotationData.getCoverDetailsByCoverID2(coverId);
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external pure
        returns(bytes4)
    {
        return 0x150b7a02;
    }

    modifier onlyTokenApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _;
    }
}