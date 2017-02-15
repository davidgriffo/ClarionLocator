
    PROGRAM


! Created with Clarion 10.0
! User: davidgriffiths
! 
!  An example of  :
!   * filtering a list of records  
!   * stepping through a list       
!   * using the locator event ( the ? in the vcr) 
!   * sorting on header
!   
! this test was expanded to recieve notice from the user clicking on the locator button
! in the vcr.
!
!  The EVENT:Locate will only work if you have imm set on the list.
!  When you add the imm property you then have to do a lot of work 
!  listening to all the other properties on the list.


    MAP      
loadList        PROCEDURE(CustomerListType fromQ, CustomerListType toQ,string filter)
randomName      PROCEDURE(),STRING

    END    
    INCLUDE('KEYCODES.CLW')

CustomerListType                QUEUE,type 
Customer                            string(100)
id                                  LONG
                                end  
! this is the original  list of customers
CustomerList                    QUEUE(CustomerListType)      
                                end
! this is the list that gets filtered and displayed in the window.
ListQueue                       QUEUE(CustomerListType)
                                end


SearchName                      CSTRING(20)  ! locator 
SearchNameCopy                  CSTRING(20)  ! a copy of the locator (so we can check it changed)

Window                          WINDOW('Locator test window'),AT(,,300,191),GRAY,ICON(ICON:Frame), |
                                        FONT('Tahoma',11,,FONT:regular),TIMER(10)
                                    LIST,AT(11,22,284,161),USE(?LIST1),IMM,VSCROLL,VCR,FROM(LISTQueue), |
                                            FORMAT('145L(2)|M~Customer Name~20L(2)|M~ ID~'),ALRT(MouseLeft)
                                    PROMPT('Find'),AT(10,6),USE(?PROMPTFind)
                                    ENTRY(@s20),AT(34,6),USE(SearchName)
                                END

i                               LONG  
cr                              string('<13,10>')   
LinesPerPage                    LONG


    CODE   
        ! create a dummy list of 200 customers
        loop i =  1 to 200   
            CustomerList.id = i
            CustomerList.Customer = randomName()
            add(CustomerList)
        END     
        sort(CustomerList,CustomerList.id)   
        ! copy this list to the window list
        Loadlist(CustomerList,ListQueue,'')
        OPEN(Window)                 
        
        ! calc the number of visable lines in the list 
        ! if the window is resizeable you would have to calc this after every resize
        LinesPerPage = ((?LIST1{PROP:Height} - ?LIST1{PROP:HeaderHeight}) / ?LIST1{PROP:LineHeight})
        if ?LIST1{prop:vcr}
            LinesPerPage -=1
        END      
     
        clear(SearchName)
        select(?LIST1)
            
        ACCEPT        
            case EVENT()  
            of EVENT:PreAlertKey
                CYCLE
            of EVENT:AlertKey 
                window{prop:text} = 'Clicked on zone ' &   PROPLIST:MouseDownZone
                case  ?LIST1{PROPLIST:MouseDownZone} 
                of LISTZONE:icon
                    window{prop:text} = ' clicked on Icon'
                of LISTZONE:nowhere
                    window{prop:text} = ' clicked on Nowhere'
                of LISTZONE:header 
                    window{prop:text} = ' clicked on header ' &   ?LIST1{PROPLIST:MouseDownField}
                    EXECUTE  ?LIST1{PROPLIST:MouseDownField}
                        sort(ListQueue,ListQueue.Customer)   
                        sort(ListQueue,ListQueue.id)   
                    END   
                END
            of EVENT:Locate    
                window{prop:text} = ' clicked on Locator ' 
                SELECT(?SearchName)    
            of EVENT:ScrollUp  
                if  ?list1{PROP:Selected} > 1
                    ?list1{PROP:Selected} = ?LIST1{PROP:Selected} -1      
                END
            of EVENT:ScrollDown     
                if  ?list1{PROP:Selected} < records(ListQueue)
                    ?list1{PROP:Selected} = ?LIST1{PROP:Selected} +1      
                END
            of EVENT:PageDown       
                if (   ?LIST1{PROP:Selected} + LinesPerPage) > records(ListQueue)
                    ?LIST1{PROP:Selected} = records( ListQueue)
                ELSE
                    ?LIST1{PROP:Selected} =   ?LIST1{PROP:Selected} + LinesPerPage
                END
                
            of EVENT:PageUp  
                if (     ?LIST1{PROP:Selected} - LinesPerPage) < 1
                    ?LIST1{PROP:Selected} =   1
                ELSE
                    ?LIST1{PROP:Selected} =   ?LIST1{PROP:Selected} - LinesPerPage
                END
                
            of EVENT:ScrollTop
                ?LIST1{PROP:Selected} = 1
            of EVENT:ScrollBottom
                ?LIST1{PROP:Selected} = records( ListQueue)
            of EVENT:ScrollDrag
                ?LIST1{PROP:Selected} = ?LIST1{PROP:VScrollPos}   
            of EVENT:Accepted
                case FIELD()  
               
                END
            
            of EVENT:Timer
                UPDATE 
                ! check if changed
                if  SearchNameCopy <>  SearchName 
                    SearchNameCopy =  SearchName     
                    loadList(CustomerList,ListQueue,SearchName)
                END
            END
        END
!!! <Summary>
!!!  Copy one list to another depending on the supplied filter
!!! </Summary>    
loadList                        PROCEDURE  (CustomerListType fromQ ,CustomerListType toQ,string filter)       
x                                   long
    code
        free(toQ)
        loop x = 1 to records(fromQ) 
            get(fromQ,x)  
            if  filter = ''  or   instring(UPPER(filter),UPPER(fromQ.Customer),1,1)
                toQ  :=: fromQ
                add(toQ)
            END
            
        end   
!!! <Summary>
!!!  return a random name
!!! </Summary> 
RandomName                      PROCEDURE()  
RName                               cstring(100)
    code
        RName = chr(val('A') + random(0,25)) ! first letter capital
        loop RANDOM(6,13) TIMES    
            RName = RName & chr(val('a') + random(0,25))
        END       
        return RName
