const Meme = artifacts.require("Meme");

require('chai')
.use(require('chai-as-promised'))
.should()

contract('Meme', (accounts) => {
    let meme 

    before(async()=>{
        meme = await Meme.deployed();
    })

    describe('deployment', async() =>{                 // functions
        it('deployes', async() =>{

            const address = meme.address
            assert.notEqual(address, '0x0')
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
        })
    })

    describe('storage', async() =>{                      // functions
        it('sets memes hash', async() =>{
            let memeHash;
            memeHash ='123'
            await meme.set(memeHash)
            const result = await meme.get()
            assert.equal(result, memeHash)
        })
    })

})