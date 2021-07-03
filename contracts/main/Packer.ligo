#include "../partials/hicetnunc.ligo"
#include "../lambdas/originate/hicProxy.ligo"

// TODO: include basicProxy is failed it use Default entry with HicProxy
// so it is required to refactor structure and move types somewhere
// #include "../lambdas/originate/basicProxy.ligo"
type shares is map(address, nat);

type action is
| Pack_mint_OBJKT of mintParams
| Pack_originate_hic_proxy of participantsMap
| Pack_originate_basic_proxy of shares

function mint_OBJKT(var params : mintParams) : bytes is Bytes.pack(params)
function originate_hic_proxy(var params : participantsMap) : bytes is Bytes.pack(params)
function originate_basic_proxy(var params : shares) : bytes is Bytes.pack(params)

function main (var params : action; var store : bytes) : (list(operation) * bytes) is
case params of
| Pack_mint_OBJKT(p) -> ((nil: list(operation)), mint_OBJKT(p))
| Pack_originate_hic_proxy(p) -> ((nil: list(operation)), originate_hic_proxy(p))
| Pack_originate_basic_proxy(p) -> ((nil: list(operation)), originate_basic_proxy(p))
end