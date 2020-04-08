{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs            #-}
{-# LANGUAGE TemplateHaskell  #-}
module Wallet.Effects(
    WalletEffects
    -- * Wallet effect
    , WalletEffect(..)
    , submitTxn
    , ownPubKey
    , updatePaymentWithChange
    , walletSlot
    , ownOutputs
    -- * Node client
    , NodeClientEffect(..)
    , publishTx
    , getClientSlot
    -- * Signing process
    , SigningProcessEffect(..)
    , addSignatures
    -- * Chain index
    , ChainIndexEffect(..)
    , startWatching
    , watchedAddresses
    ) where

import           Control.Monad.Freer.TH (makeEffect)
import qualified Data.Set               as Set
import           Ledger                 (Address, PubKey, PubKeyHash, Slot, Tx, TxIn, TxOut, Value)
import           Ledger.AddressMap      (AddressMap, UtxoMap)

data WalletEffect r where
    SubmitTxn :: Tx -> WalletEffect ()
    OwnPubKey :: WalletEffect PubKey
    UpdatePaymentWithChange :: Value -> (Set.Set TxIn, Maybe TxOut) -> WalletEffect (Set.Set TxIn, Maybe TxOut)
    WalletSlot :: WalletEffect Slot
    OwnOutputs :: WalletEffect UtxoMap
makeEffect ''WalletEffect

data NodeClientEffect r where
    PublishTx :: Tx -> NodeClientEffect ()
    GetClientSlot :: NodeClientEffect Slot
makeEffect ''NodeClientEffect

data SigningProcessEffect r where
    AddSignatures :: [PubKeyHash] -> Tx -> SigningProcessEffect Tx
makeEffect ''SigningProcessEffect

-- | Access a (plutus-specific) chain index. The chain index keeps track of the
--   datums that are associated with unspent transaction outputs. Addresses that
--   are of interest need to be added with 'startWatching' before their outputs
--   show up in the 'AddressMap' returned by 'watchedAddresses'.
data ChainIndexEffect r where
    StartWatching :: Address -> ChainIndexEffect ()
    WatchedAddresses :: ChainIndexEffect AddressMap
makeEffect ''ChainIndexEffect

-- | Effects that allow contracts to interact with the blockchain
type WalletEffects =
    '[ WalletEffect
    , NodeClientEffect
    , SigningProcessEffect
    , ChainIndexEffect
    ]
