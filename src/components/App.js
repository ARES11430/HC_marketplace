import React, { Component } from 'react';
import Web3 from 'web3';
import './App.css';
import HCTMarketplace from '../abis/HCTMarketplace.json'


const ipfsClient = require('ipfs-http-client')
const ipfs = ipfsClient({ host: 'ipfs.infura.io', port: 5001, protocol: 'https' }) // leaving out the arguments will default to these values

class App extends Component {

  async componentWillMount() {
    await this.loadWeb3()
    await this.loadBlockchainData()
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }

  async loadBlockchainData() {
    const web3 = window.web3
    // Load account
    const accounts = await web3.eth.getAccounts()
    console.log(accounts)
    this.setState({ account: accounts[0] })
    const networkId = await web3.eth.net.getId()
    const networkData = HCTMarketplace.networks[networkId]
    if(networkData) {
      const abi = HCTMarketplace.abi
      const address = networkData.address
      const contract = web3.eth.Contract(abi, address)
      this.setState({ contract })

      const postCount = await contract.methods.totalPosts().call();
      console.log(postCount);
  

      this.state.contract.events.PosterCreated({}, function(error, event) { 
        const seller = event.returnValues['party']
        const postID = event.returnValues['postID']
        const ipfsHash = event.returnValues['ipfsHash']
        console.log(event.returnValues)
        console.log(postID)
        console.log(seller) 
        console.log(ipfsHash)  
        
       })

      for(var i=0;i<postCount;i++){

        const post =  await contract.methods.getPost(i).call();
        this.setState({seller2: post[0]})
        this.setState({object2: post[1]})
        this.setState({ipfsHash: post[2]})
        this.setState({escrowAgent2: post[3]})
        this.setState({auditor2: post[4]})
        this.setState({isPostActive: post[5]})
        this.setState({escrow2: post[6]})
 
        /* var seller = this.state.seller2;
        var object = this.state.object2;
        var ipfsHash = this.state.ipfsHash;
        var escrowAgent = this.state.escrowAgent2;
        var escrow = this.state.escrow2; */
  
        
  
        console.log(this.state.seller2);
        console.log(this.state.object2);
        console.log(this.state.ipfsHash);
        console.log(this.state.escrowAgent2);
        console.log(this.state.auditor2);
        console.log(this.state.isPostActive);
        console.log(this.state.escrow2);
        
      }
      
  
      
      
    } else {
      window.alert('Smart contract not deployed to detected network.')
    }
  }

  constructor(props) {
    super(props)

    
    this.state = {
      seller:'',
      seller2:'',
      object: '',
      object2: '',
      ipfsHash: '',
      escrow: 0,
      escrow2: 0,
      auditor: '',
      auditor2: '',
      isPostActive: true,
      escrowAgent: '',
      escrowAgent2: '',
      contract: null,
      web3: null,
      buffer: null,
      account: null
    }
  }

  captureFile = (event) => {
    event.preventDefault()
    const file = event.target.files[0]
    const reader = new window.FileReader()
    reader.readAsArrayBuffer(file)
    reader.onloadend = () => {
      this.setState({ buffer: Buffer(reader.result) })
      console.log('buffer', this.state.buffer)
    }
  }
  sellerState = (event) => {
    event.preventDefault()
    this.setState({seller: event.target.value});
  }
  objectState = (event) => {
    event.preventDefault()
    this.setState({object: event.target.value});
  }
  escrowState = (event) => {
    event.preventDefault()
    this.setState({escrow: event.target.value});
  }
  auditorState = (event) => {
    event.preventDefault()
    this.setState({auditor: event.target.value});
  }
  escrowAgentState = (event) => {
    event.preventDefault()
    this.setState({escrowAgent: event.target.value});
  }

  onSubmit = (event) => {
    event.preventDefault() 
    ipfs.add(this.state.buffer, (error, result) => {
      console.log("Submitting pic to ipfs...")
      const _ipfsHash = result[0].hash
     // const _seller = this.state.seller
      const _object = this.state.object
      const _escrow = this.state.escrow
      const _auditor = this.state.auditor
      const _escrowAgent = this.state.escrowAgent
      if(error) {
        console.error(error)
        return
      }
       this.state.contract.methods.createPost(_ipfsHash, _object, _escrow, _auditor, _escrowAgent).send({ from: this.state.account }).then((r) => {
        //  this.setState({seller: _seller})     
          this.setState({object: _object})
          this.setState({ipfsHash: _ipfsHash})
          this.setState({escrow: _escrow})
          this.setState({auditor: _auditor})
          this.setState({escrowAgent: _escrowAgent})  
       })      
    })
  }

   render() {
  
    return (
      <div>
        <nav className="navbar navbar-dark fixed-top bg-dark flex-md-nowrap p-0 shadow">
          <a
            className="navbar-brand col-sm-3 col-md-2 mr-0"
            href=""
            target="_blank"
            rel="noopener noreferrer"
          >
            Handi Craft
          </a>
        </nav>
        <div className="container-fluid mt-5">
          <div className="row">
            <main role="main" className="col-lg-12 d-flex text-center">
              <div className="content mr-auto ml-auto">
                <a
                  href={`https://ipfs.infura.io/ipfs/${this.state.ipfsHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >           
                  <img src={`https://ipfs.infura.io/ipfs/${this.state.ipfsHash}`} />
                </a>
                <br></br>
                
                Seller:  {this.state.seller2}
                <br></br>
                <br></br>
                Escrow Agent:  {this.state.escrowAgent2}
                <br></br>
                <br></br>           
                auditor: {this.state.auditor2}
                <p>&nbsp;</p>          

                             
                <h2>Change Pic</h2>
   
                <form onSubmit={this.onSubmit} >
                  <input type='file' required name='ipfsHash' onChange={this.captureFile} />
                  {/* <input type='text' required name='seller' hint='seller address' onChange={this.sellerState} /> */}
                  object type:&nbsp;&nbsp;<input type='number' required name='type' hint='object type' onChange={this.objectState} />&nbsp;&nbsp;                  
                  Escrow amount:&nbsp;&nbsp;<input type='text' required name='escrow' hint='escrow amount' onChange={this.escrowState} />&nbsp;&nbsp;
                  Auditor Address:&nbsp;&nbsp;<input type='text' required name='auditor' hint='auditor address' onChange={this.auditorState} />&nbsp;&nbsp;
                  Escrow Agesnt Address:&nbsp;&nbsp; <input type='text' required name='escrowAgent' hint='escrowAgent address' onChange={this.escrowAgentState} />&nbsp;&nbsp;
                  <br></br><br></br><br></br><br></br>
                  <input type='submit' name='Insert' />&nbsp;&nbsp;
                </form>
              </div>
            </main>
          </div>
        </div>
      </div>
    );
  }
}

export default App;
