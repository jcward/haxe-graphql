// tslint:disable
// graphql typescript definitions

declare namespace GQL {
  interface IGraphQLResponseRoot {
    data?: IQuery | IMutation;
    errors?: Array<IGraphQLResponseError>;
  }

  interface IGraphQLResponseError {
    /** Required for all errors */
    message: string;
    locations?: Array<IGraphQLResponseErrorLocation>;
    /** 7.2.2 says 'GraphQL servers may provide additional entries to error' */
    [propName: string]: any;
  }

  interface IGraphQLResponseErrorLocation {
    line: number;
    column: number;
  }

  interface IQuery {
    __typename: 'Query';
    hero: Character | null;
    reviews: Array<IReview>;
    search: Array<SearchResult>;
    character: Character | null;
    droid: IDroid | null;
    human: IHuman | null;
    starship: IStarship | null;
  }

  interface IHeroOnQueryArguments {
    /**
     * @default NEWHOPE
     */
    episode?: Episode | null;
  }

  interface IReviewsOnQueryArguments {
    episode: Episode;
  }

  interface ISearchOnQueryArguments {
    text: string;
  }

  interface ICharacterOnQueryArguments {
    id: string;
  }

  interface IDroidOnQueryArguments {
    id: string;
  }

  interface IHumanOnQueryArguments {
    id: string;
  }

  interface IStarshipOnQueryArguments {
    id: string;
  }

  enum Episode {
    NEWHOPE = 'NEWHOPE',
    EMPIRE = 'EMPIRE',
    JEDI = 'JEDI'
  }

  type Character = IHuman | IDroid;

  interface ICharacter {
    __typename: 'Character';
    id: string;
    name: string;
    friends: Array<Character> | null;
    friendsConnection: IFriendsConnection;
    appearsIn: Array<Episode>;
  }

  interface IFriendsConnectionOnCharacterArguments {
    first?: number | null;
    after?: string | null;
  }

  interface IFriendsConnection {
    __typename: 'FriendsConnection';
    totalCount: number;
    edges: Array<IFriendsEdge> | null;
    friends: Array<Character> | null;
    pageInfo: IPageInfo;
  }

  interface IFriendsEdge {
    __typename: 'FriendsEdge';
    cursor: string;
    node: Character | null;
  }

  interface IPageInfo {
    __typename: 'PageInfo';
    startCursor: string | null;
    endCursor: string | null;
    hasNextPage: boolean;
  }

  interface IReview {
    __typename: 'Review';
    stars: number;
    commentary: string | null;
  }

  type SearchResult = IHuman | IDroid | IStarship;

  interface IHuman {
    __typename: 'Human';
    id: string;
    name: string;
    height: number;
    mass: number | null;
    friends: Array<Character> | null;
    friendsConnection: IFriendsConnection;
    appearsIn: Array<Episode>;
    starships: Array<IStarship> | null;
  }

  interface IHeightOnHumanArguments {
    /**
     * @default METER
     */
    unit?: LengthUnit | null;
  }

  interface IFriendsConnectionOnHumanArguments {
    first?: number | null;
    after?: string | null;
  }

  type IName = IHuman | IDroid;

  interface IIName {
    __typename: 'IName';
    name: string;
  }

  enum LengthUnit {
    METER = 'METER',
    FOOT = 'FOOT'
  }

  interface IStarship {
    __typename: 'Starship';
    id: string;
    name: string;
    length: number;
  }

  interface ILengthOnStarshipArguments {
    /**
     * @default METER
     */
    unit?: LengthUnit | null;
  }

  interface IDroid {
    __typename: 'Droid';
    id: string;
    name: string;
    friends: Array<Character> | null;
    friendsConnection: IFriendsConnection;
    appearsIn: Array<Episode>;
    primaryFunction: string | null;
  }

  interface IFriendsConnectionOnDroidArguments {
    first?: number | null;
    after?: string | null;
  }

  interface IMutation {
    __typename: 'Mutation';
    createReview: IReview | null;
  }

  interface ICreateReviewOnMutationArguments {
    episode: Episode;
  }
}

// tslint:enable

