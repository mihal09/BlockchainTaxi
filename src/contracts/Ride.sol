pragma solidity ^0.8.4;


contract Ride {
    uint public value;
    address payable client;
    address payable driver;

    enum State { Created, Locked, Release, Inactive }
    // The state variable has a default value of the first member, `State.created`
    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    /// Only the client can call this function.
    error OnlyClient();
    /// Only the driver can call this function.
    error OnlyDriver();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();

    modifier onlyClient() {
        if (msg.sender != client)
            revert OnlyClient();
        _;
    }

    modifier onlyDriver() {
        if (msg.sender != driver)
            revert OnlyDriver();
        _;
    }

    modifier inState(State _state) {
        if (state != _state)
            revert InvalidState();
        _;
    }

    event Aborted();
    event DriveConfirmed();
    event DriveFinished();
    event DriverRefunded();

    constructor() payable public {
        client = payable(msg.sender);
        value = msg.value / 2;
        if ((2 * value) != msg.value)
            revert ValueNotEven();
    }


    // client cancels ride if no driver accepted his request
    function abort()
        public
        onlyClient
        inState(State.Created)
    {
        state = State.Inactive;
        emit Aborted();
        client.transfer(address(this).balance);
    }

    // driver accepts a ride by sending *value* of ether to the contract
    function confirmDrive()
        public
        inState(State.Created)
        condition(msg.value == value)
        payable
    {
        emit DriveConfirmed();
        driver = payable(msg.sender);
        state = State.Locked;
    }

    // client confirms that the drive has finished
    // client receives his locked ether
    function finishDrive()
        public
        onlyClient
        inState(State.Locked)
    {
        state = State.Release;
        emit DriveFinished();

        client.transfer(value);
    }

    // driver receives the payment for the ride
    // this function pays back locked funds of the driver
    function refundDriver()
        public
        onlyDriver
        inState(State.Release)
    {
        state = State.Inactive;
        emit DriverRefunded();

        driver.transfer(2 * value);
    }

}
