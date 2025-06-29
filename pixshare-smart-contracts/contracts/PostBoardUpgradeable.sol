// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @title  PixShare – Upgradeable PostBoard V1 (Irys native tips)
contract PostBoardUpgradeable is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ================================================================
                                STORAGE
    ================================================================ */
    struct Post {
        address author;
        bytes32[] irysTxIds;  // multi‑image array
        string caption;
        uint64 timestamp;
        uint32 likes;
        uint256 totalTips;    // in native IRYS wei
        bool deleted;
    }

    struct Comment {
        address commenter;
        string text;
        uint64 timestamp;
    }

    CountersUpgradeable.Counter private _ids;            // post IDs
    mapping(uint256 => Post) public posts;               // postId ⇒ Post
    mapping(uint256 => mapping(address => bool)) public liked; // postId ⇒ user ⇒ liked?
    mapping(uint256 => Comment[]) private _comments;     // postId ⇒ list

    /* ================================================================
                                EVENTS
    ================================================================ */
    event PostCreated(
        uint256 indexed id,
        address indexed author,
        bytes32[] irysTxIds,
        string caption
    );
    event PostDeleted(uint256 indexed id);
    event PostLiked(uint256 indexed id, address indexed liker, uint256 totalLikes);
    event PostTipped(uint256 indexed id, address indexed from, uint256 amount, uint256 totalTips);
    event CommentAdded(uint256 indexed id, address indexed commenter, string text);

    /* ================================================================
                           INITIALIZATION
    ================================================================ */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // proxy pattern
    }

    /// @param initialOwner  address that can upgrade the contract
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    /// @dev only owner (you) can authorize upgrades
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ================================================================
                              MODIFIERS
    ================================================================ */
    modifier validPost(uint256 id) {
        require(id < _ids.current(), "Post: nonexistent");
        require(!posts[id].deleted, "Post: deleted");
        _;
    }

    /* ================================================================
                              CORE LOGIC
    ================================================================ */

    /// @notice Create a post with 1‑N Irys transaction IDs
    function createPost(bytes32[] calldata irysTxIds, string calldata caption) external {
        require(irysTxIds.length > 0, "Need at least 1 image");

        uint256 id = _ids.current();
        posts[id] = Post({
            author: msg.sender,
            irysTxIds: irysTxIds,
            caption: caption,
            timestamp: uint64(block.timestamp),
            likes: 0,
            totalTips: 0,
            deleted: false
        });

        emit PostCreated(id, msg.sender, irysTxIds, caption);
        _ids.increment();
    }

    /// @notice Author can soft‑delete their post
    function deletePost(uint256 id) external validPost(id) {
        require(msg.sender == posts[id].author, "Not author");
        posts[id].deleted = true;
        emit PostDeleted(id);
    }

    /// @notice Like a post once per wallet
    function likePost(uint256 id) external validPost(id) {
        require(!liked[id][msg.sender], "Already liked");
        liked[id][msg.sender] = true;
        posts[id].likes += 1;
        emit PostLiked(id, msg.sender, posts[id].likes);
    }

    /// @notice Tip the author with native IRYS (send value)
    function tipPost(uint256 id) external payable validPost(id) {
        require(msg.value > 0, "Zero tip");

        Post storage p = posts[id];
        p.totalTips += msg.value;
        payable(p.author).transfer(msg.value);

        emit PostTipped(id, msg.sender, msg.value, p.totalTips);
    }

    /// @notice Add a comment to a post
    function addComment(uint256 id, string calldata text) external validPost(id) {
        require(bytes(text).length > 0, "Empty comment");

        _comments[id].push(Comment({
            commenter: msg.sender,
            text: text,
            timestamp: uint64(block.timestamp)
        }));
        emit CommentAdded(id, msg.sender, text);
    }

    /* ================================================================
                              VIEWERS
    ================================================================ */

    /// @notice Get a single post
    function getPost(uint256 id) external view validPost(id) returns (Post memory) {
        return posts[id];
    }

    /// @notice Get all comments for a post
    function getComments(uint256 id) external view returns (Comment[] memory) {
        return _comments[id];
    }

    /// @notice Get total number of posts (including deleted)
    function totalPosts() external view returns (uint256) {
        return _ids.current();
    }
}