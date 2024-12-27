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
        
        block.receipts[0].result.expectOk().expectUint(0); // First course ID should be 0
        block.receipts[1].result.expectErr(types.uint(100)); // err-owner-only
    }
});

Clarinet.test({
    name: "Test course enrollment",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // First create a course
        let block = chain.mineBlock([
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Then test enrollment
        let enrollBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'enroll-in-course', [
                types.uint(0)
            ], student.address)
        ]);
        
        enrollBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify enrollment
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'get-student-progress', [
                types.principal(student.address),
                types.uint(0)
            ], deployer.address)
        ]);
        
        const enrollment = verifyBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(enrollment['enrolled'], true);
        assertEquals(enrollment['progress'], types.uint(0));
    }
});

Clarinet.test({
    name: "Test progress tracking and certificate issuance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Setup: Create course and enroll student
        let setupBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('code-pulse', 'enroll-in-course', [
                types.uint(0)
            ], student.address)
        ]);
        
        // Update progress
        let progressBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'update-progress', [
                types.uint(0),
                types.uint(100)
            ], student.address)
        ]);
        
        progressBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Issue certificate
        let certBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'issue-certificate', [
                types.uint(0),
                types.principal(student.address)
            ], deployer.address)
        ]);
        
        certBlock.receipts[0].result.expectOk().expectUint(0); // First certificate ID
    }
});