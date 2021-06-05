(* Including hic et nunc interface: *)
#include "../partials/hicetnunc.ligo"


(* Including common functions: *)
#include "../partials/general.ligo"


(* approval types that used to sign contract:
    - Unsigned:
        1. this is default value, used when contract created for all core particiapnts
        2. this value can be setted using Sign call to unsign contract if participant
            decides to cancel his sign
        3. this value would be setted if participant signed for Limited number of
            mints and all this mints have been done
    
    - Unlimited:
        This means that participant allows contract administrator to mint as many works
            as they would need to without any limites. User always able to call sign
            again and change it to Limited / Unsigned state

    - Limited:
        This means that participant allows contract administrator to mint exactly
            N works
*)

type approvalType is
| Unsigned
| Unlimited
| Limited of nat


type action is
| Mint_OBJKT of mintParams
| Swap of swapParams
| Cancel_swap of cancelSwapParams
| Collect of collectParams
| Curate of curateParams
| Default of unit
| Sign of approvalType


type mintApprovalsLedger is map(address, approvalType)


type storage is record [
    (* administrator is originator of the contract, this is the only one who can call mint *)
    administrator : address;

    (* shares is map of all participants with the shares that they would recieve *)
    shares : map(address, nat);

    (* the sum of the shares should be equal to totalShares *)
    totalShares : nat;

    (* address of the Hic Et Nunc Minter (mainnet: KT1Hkg5qeNhfwpKW4fXvq7HGZB9z2EnmCCA9) *)
    hicetnuncMinterAddress : address;

    (* list of the core participants with their mint approvals. Contract can
        call mint only when all approvals Unlimited or Limited with nat > 0 *)
    mintApprovals : mintApprovalsLedger;
]


function checkSenderIsAdmin(var store : storage) : unit is
    if (Tezos.sender = store.administrator) then unit
    else failwith("Entrypoint can call only administrator");


function checkAndReduceMintApprovals(
    var mintApprovals: mintApprovalsLedger) : mintApprovalsLedger is

block {

    for participantAddress -> approvalType in map mintApprovals block {
        mintApprovals[participantAddress] := case approvalType of
        | Unsigned -> (failwith("Can't mint with unsigned contract") : approvalType)
        | Unlimited -> Unlimited
        | Limited(count) -> if count > 1n  
            then Limited(abs(count - 1n))
            else Unsigned
        end;
    }

} with mintApprovals


function mint_OBJKT(var store : storage; var params : mintParams) : (list(operation) * storage) is
block {
    checkSenderIsAdmin(store);
    store.mintApprovals := checkAndReduceMintApprovals(store.mintApprovals);

    const callToHic = callMintOBJKT(store.hicetnuncMinterAddress, params);
} with (list[callToHic], store)


function swap(var store : storage; var params : swapParams) : (list(operation) * storage) is
block {
    checkSenderIsAdmin(store);
    const callToHic = callSwap(store.hicetnuncMinterAddress, params);
} with (list[callToHic], store)


function cancelSwap(var store : storage; var params : cancelSwapParams) : (list(operation) * storage) is
block {
    checkSenderIsAdmin(store);
    const callToHic = callCancelSwap(store.hicetnuncMinterAddress, params);
} with (list[callToHic], store)


function collect(var store : storage; var params : collectParams) : (list(operation) * storage) is
block {
    checkSenderIsAdmin(store);
    const callToHic = callCollect(store.hicetnuncMinterAddress, params);
} with (list[callToHic], store)


function curate(var store : storage; var params : curateParams) : (list(operation) * storage) is
block {
    checkSenderIsAdmin(store);
    const callToHic = callCurate(store.hicetnuncMinterAddress, params);
} with (list[callToHic], store)


function default(var store : storage) : (list(operation) * storage) is
block {
    var operations : list(operation) := nil;
    for participantAddress -> participantShare in map store.shares block {
        const payoutAmount : tez = Tezos.amount * participantShare / store.totalShares;

        const receiver : contract(unit) = getReceiver(participantAddress);
        const op : operation = Tezos.transaction(unit, payoutAmount, receiver);
        operations := op # operations
    }

    (* TODO: return dust to the last participant? *)
} with (operations, store)


function sign(
    var store : storage;
    const approval : approvalType) : (list(operation) * storage) is
block {
    skip;
} with ((nil: list(operation)), store)


function main (var params : action; var store : storage) : (list(operation) * storage) is
case params of
| Mint_OBJKT(p) -> mint_OBJKT(store, p)
| Swap(p) -> swap(store, p)
| Cancel_swap(p) -> cancelSwap(store, p)
| Collect(p) -> collect(store, p)
| Curate(p) -> curate(store, p)
| Default -> default(store)
| Sign(p) -> sign(store, p)
end

