pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);
  event TokenVestingRevoked(address token);

  uint256 private _start;
  uint256 private _duration;
  uint256 private tokenAmount = 2800000*10**18;

  bool private _revocable;


  // beneficiary of tokens after they are released
  mapping (address => uint256) private _beneficiaries;
  mapping (address => uint256) private _released;
  mapping (address => bool) private _revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * beneficiary, gradually in a linear fashion until start + duration. By then all
   * of the balance will have vested.
   * @param start the time (as Unix time) at which point vesting starts
   * @param duration duration in seconds of the period in which the tokens will vest
   * @param revocable whether the vesting is revocable or not
   */
  constructor(
    uint256 start,
    uint256 duration,
    bool revocable
  )
    public
  {
    require(duration > 0);
    require(start + duration > block.timestamp);

    _revocable = revocable;
    _duration = duration;
    _start = start;
  }
  
  /**
   * @return the start time of the token vesting.
   */
  function start() public view returns(uint256) {
    return _start;
  }

  /**
   * @return the duration of the token vesting.
   */
  function duration() public view returns(uint256) {
    return _duration;
  }

  /**
   * @return true if the vesting is revocable.
   */
  function revocable() public view returns(bool) {
    return _revocable;
  }

  /**
   * @return the amount of the token released.
   */
  function released(address token) public view returns(uint256) {
    return _released[token];
  }

  /**
   * @return true if the token is revoked.
   */
  function revoked(address token) public view returns(bool) {
    return _revoked[token];
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(address token) public {
    require(_beneficiaries[msg.sender] > 0, "FORBIDDEN : You are not part of the beneficiaries");

    uint256 unreleased = _releasableAmount(token, msg.sender);

    require(unreleased > 0);

    _released[token] = _released[token] + unreleased;
    _beneficiaries[msg.sender] -= unreleased;

    IERC20(token).transfer(msg.sender, unreleased);

    emit TokensReleased(token, unreleased);
  }


  function allowVestingAmount(address beneficiary, uint256 amount) public onlyOwner {
      _beneficiaries[beneficiary] += amount;
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(address token) public onlyOwner {
    require(_revocable);
    require(!_revoked[token]);

    uint256 balance = IERC20(token).balanceOf(address(this));

    uint256 unreleased = tokenAmount - _released[token];
    uint256 refund = balance - unreleased;

    _revoked[token] = true;

    IERC20(token).transfer(owner(), refund);

    emit TokenVestingRevoked(token);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(address token, address beneficiary) private view returns (uint256) {
    return _vestedAmount(token, beneficiary) - _released[token];
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(address token, address beneficiary) private view returns (uint256) {
    uint256 currentBalance = _beneficiaries[beneficiary];
    uint256 totalBalance = currentBalance + _released[token];

    if (block.timestamp >= _start + _duration || _revoked[token]) {
      return totalBalance;
    } else {
      return (totalBalance * (block.timestamp - _start)) / _duration;
    }
  }
}