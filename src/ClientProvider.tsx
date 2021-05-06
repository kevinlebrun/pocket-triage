import * as React from "react";

import Client from "./client";

export const ClientContext = React.createContext({ client: new Client("") });

interface State {
  client: Client;
}

interface Props {
  baseURL: string;
}

class ClientProvider extends React.Component<Props, State> {
  public constructor(props: Props) {
    super(props);

    this.state = {
      client: new Client(props.baseURL),
    };
  }

  public render(): React.ReactNode {
    const { children } = this.props;

    return (
      <ClientContext.Provider value={this.state}>
        {children}
      </ClientContext.Provider>
    );
  }
}

export default ClientProvider;

export const useClient = (): Client => {
  const { client } = React.useContext(ClientContext);
  return client;
};
