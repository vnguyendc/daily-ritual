import { Request, Response } from 'express';
export declare class IntegrationsController {
    static getIntegrations(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getWhoopAuthUrl(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static connectWhoop(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static disconnectWhoop(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static whoopCallback(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static syncWhoop(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
//# sourceMappingURL=integrations.d.ts.map