import { Component, type ReactNode } from 'react'
export class ErrorBoundary extends Component<{children:ReactNode},{failed:boolean}> {
  state={failed:false}
  static getDerivedStateFromError(){return {failed:true}}
  render(){if(!this.state.failed)return this.props.children
    return <main className="recovery-screen" role="alert"><h1>Workspace could not be displayed</h1><p>Your browser records have not been deleted. Reload the workspace to try again.</p><button className="button primary" onClick={()=>window.location.reload()}>Reload workspace</button></main>
  }
}
