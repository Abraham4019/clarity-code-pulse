import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test course creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Test successful course creation by owner
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address),
            
            // Test failed course creation by non-owner
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("JavaScript"),
                types.uint(100)
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        block.receipts[1].result.expectErr(types.uint(100));
    }
});

Clarinet.test({
    name: "Test lesson creation and completion",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Create course and lesson
        let setupBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('code-pulse', 'add-lesson', [
                types.uint(0),
                types.ascii("Variables"),
                types.uint(10)
            ], deployer.address)
        ]);
        
        setupBlock.receipts[0].result.expectOk().expectUint(0);
        setupBlock.receipts[1].result.expectOk().expectUint(0);
        
        // Enroll student
        let enrollBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'enroll-in-course', [
                types.uint(0)
            ], student.address)
        ]);
        
        enrollBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Complete lesson
        let completeBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(0)
            ], student.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test lesson rating system",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Setup course and lesson
        let setupBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('code-pulse', 'add-lesson', [
                types.uint(0),
                types.ascii("Variables"),
                types.uint(10)
            ], deployer.address)
        ]);
        
        // Rate lesson
        let rateBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'rate-lesson', [
                types.uint(0),
                types.uint(5),
                types.ascii("Great lesson!")
            ], student.address)
        ]);
        
        rateBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify rating
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'get-lesson-rating', [
                types.principal(student.address),
                types.uint(0)
            ], deployer.address)
        ]);
        
        const rating = verifyBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(rating['rating'], types.uint(5));
    }
});
